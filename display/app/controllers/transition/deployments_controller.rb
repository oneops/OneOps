class Transition::DeploymentsController < ApplicationController
  before_filter :find_assembly_and_environment, :except => [:log_data, :time_stats, :progress]
  before_filter :find_deployment, :only => [:status, :show, :edit, :update, :time_stats, :progress]

  def index
    if @environment || @assembly
      ns_path = @environment ? "#{@environment.nsPath}/#{@environment.ciName}/bom" : assembly_ns_path(@assembly)
      size    = (params[:size].presence || 1000).to_i
      offset  = (params[:offset].presence || 0).to_i
      sort    = params[:sort].presence || {'created' => 'desc'}
      filter  = params[:filter]
      search_params = {:nsPath => ns_path, :size => size, :from => offset, :sort => sort, :_silent => []}
      search_params[:query] = filter if filter.present?
      # @deployments = Cms::Deployment.all(:params => {:nsPath => ns_path})
      @deployments = Cms::Deployment.search(search_params)

      set_pagination_response_headers(@deployments)
    else
      # Org scope.
      unless is_admin? || has_org_scope?
        unauthorized
        return
      end

      opts = {}
      profiles = params[:profiles]
      if profiles.present?
        profiles = (profiles.is_a?(Array) ? profiles : profiles.split(',')).to_map
        envs     = Cms::Ci.all(:params => {:nsPath      => organization_ns_path,
                                           :recursive   => true,
                                           :ciClassName => 'manifest.Environment'})
        opts[:nsPath] = envs.inject([]) do |a, e|
          a << environment_bom_ns_path(e) if profiles[e.ciAttributes.profile]
          a
        end
      else
        opts[:nsPath] = "#{organization_ns_path}/*"
      end

      created = params[:created]
      if created.present?
        created = created.split(',')
        opts[:created] = (Time.at(created[0].to_i) .. (Time.at(created[1] ? Time.at(created[1].to_i) : Time.now)))
        opts[:sort] = 'created'
      end
      @deployments = Cms::Deployment.search(opts)
    end

    respond_to do |format|
      format.html {render 'transition/environments/_deployments'}
      format.js {render :action => :index}
      format.json {render :json => @deployments}
    end
  end

  def latest
    @deployment = Cms::Deployment.latest(:nsPath => "#{environment_ns_path(@environment)}/bom")
    render_json_ci_response(@deployment.present?, @deployment)
  end

  def status
    step = nil
    if @deployment.deploymentState != 'complete' && @deployment.deploymentState != 'failed'
      step = params[:exec_order].to_i
      step = nil unless step > 0
    end
    load_deployment_states(step)

    respond_to do |format|
      format.js do
        @deployment.log_data = {}

        current_state  = params[:current_state]
        if current_state == 'pending' || current_state != @deployment.deploymentState
          load_state_history
          load_approvals
        end

        record_ids = params[:deployment_record_ids]
        if record_ids.present?
          @deployment.log_data = get_log_data(record_ids.map(&:to_i)).inject({}) do |m, log|
            m[log['id'].to_i] = log['logData']
            m
          end
        end

        load_time_stats if step.nil? || @deployment_rfc_cis_info.values.all? {|i| i[:state] == 'complete' || i[:state] == 'failed' || i[:state] == 'canceled'}

        render :action => :status
      end

      format.json do
        @deployment.rfc_info = @deployment_rfc_cis_info if @deployment
        render_json_ci_response(@deployment.present?, @deployment)
      end
    end
  end

  def show
    @release = Cms::ReleaseBom.find(@deployment.releaseId)
    release_rfc_cis = @release.rfc_cis.inject({}) {|h, c| h.update(c.rfcId => c) }
    @rfc_cis = @deployment.rfc_cis.collect { |rfc| release_rfc_cis[rfc.rfcId].deployment = rfc; release_rfc_cis[rfc.rfcId] }
    release_rfc_relations = @release.rfc_relations.inject({}) {|h, c| h.update(c.rfcId => c) }
    @rfc_relations = @deployment.rfc_relations.collect { |rfc| release_rfc_relations[rfc.rfcId].deployment = rfc; release_rfc_relations[rfc.rfcId] }

    respond_to do |format|
      format.js do
        @manifest = Cms::Release.find(@release.parentReleaseId)

        load_time_stats
        load_state_history
        load_approvals
        load_clouds_and_platforms

        render :action => :show
      end

      format.json do
        render :json => {:rfc_cis => @rfc_cis, :rfc_relations => @rfc_relations}
      end
    end
  end

  def new
    compile_status
    render :action => :edit
  end

  def compile_status
    if @environment.ciState != 'locked' && (@environment.comments.blank? || !@environment.comments.start_with?('ERROR:'))
      find_open_bom_release
      if request.format.json?
        if @release
          @release.rfcs = {:cis => @release.rfc_cis, :relations => @release.rfc_relations}
          @environment.bom = @release
        end
        render_json_ci_response(true, @environment)
      else
      if @release
        # Deployment might have been already started in a separate browser session.
        @deployment = Cms::Deployment.latest(:releaseId => @release.releaseId)
        @deployment = Cms::Deployment.build(:releaseId => @release.releaseId) unless @deployment && @deployment.deploymentState == 'active'
        load_bom_release_data

        @manifest = Cms::Release.find(@release.parentReleaseId)
        check_for_override
        @cost, _ = Transistor.environment_cost(@environment, true, false)
        end
      end
    end
  end

  def create
    deployment_hash   = params[:cms_deployment]
    override_password = deployment_hash.delete(:override_password)
    @deployment       = Cms::Deployment.build(deployment_hash)
    ok                = true

    if check_for_override
      ok = current_user.authenticate(override_password)
      @deployment.errors.add(:base, 'invalid password, you must provide valid password to proceed') unless ok
    end

    ok = execute(@deployment, :save) if ok

    respond_to do |format|
      format.js do
        if ok
          @release = Cms::ReleaseBom.find(@deployment.releaseId)
          load_state_history
          load_approvals
          load_bom_release_data
          render :action => :edit
        else
          flash[:error] = "Failed to create deployment: #{@deployment.errors.full_messages.join(';')}."
          render :js => ''
        end
      end

      format.json { render_json_ci_response(ok, @deployment) }
    end
  end

  def edit
    load_state_history
    load_approvals

    respond_to do |format|
      format.js do
        @release = Cms::ReleaseBom.find(@deployment.releaseId)
        load_bom_release_data

        render :action => :edit
      end

      format.json do
        @deployment.state_history = @state_history
        @deployment.approvals     = @approvals
        render_json_ci_response(true, @deployment)
      end
    end
  end

  def update
    # TODO 7/27/2015  This is just a temp code for backward compatibility to mimic old-style deploymet approvals/rejection by
    # auto approving/rejecting all pending approval records.  This should be removed eventually.  All deployment
    # approvals/rejections should be done via new deployment approval record settling.
    cms_deployment = params[:cms_deployment]
    deployment_state = cms_deployment[:deploymentState]

    approving = deployment_state == 'active'
    if @deployment.deploymentState == 'pending' && (approving || deployment_state == 'canceled')
      comments = cms_deployment[:comments]
      load_approvals
      if @approvals.present?
        approvals_to_settle = @approvals.select {|a| a.state == 'pending'}.map do |a|
          {:approvalId   => a.approvalId,
           :deploymentId => @deployment.deploymentId,
           :state        => approving ? 'approved' : 'rejected',
           :expiresIn    => 1,
           :comments     => "#{'!! ' if approving}#{comments}"}
        end

        if approvals_to_settle.present?
          ok, message = Cms::DeploymentApproval.settle(approvals_to_settle)
          @deployment.errors.add(:base, message) unless ok
        else
          ok = true
        end
      else
        ok = execute(@deployment, :update_attributes, cms_deployment)
      end
    else
      ok = execute(@deployment, :update_attributes, cms_deployment)
    end

    @deployment.check_pausing_state if ok

    respond_to do |format|
      format.js do
        if ok
          edit
        else
          flash[:error] = "Failed to update: #{@deployment.errors.full_messages}"
          render :js => ''
        end
      end

      format.json { render_json_ci_response(ok, @deployment) }
    end
  end

  def log_data
    rfc_id = params[:rfcId].to_i
    @deployment_ci = Cms::DeploymentCi.all(:params => {:deploymentId => params[:id]}).find {|r| r.rfcId == rfc_id}
    unless @deployment_ci
      render :text => 'Deployment record not found', :status => :not_found
      return
    end

    ids = [@deployment_ci.dpmtRecordId]
    raw_data  = get_log_data(ids)
    @log_data = raw_data.blank? ? [] : raw_data[0]['logData']
    respond_to do |format|
      format.html do
        @rfc = Cms::RfcCi.find(rfc_id)
        render :layout => 'log'
      end
      format.js
      format.json { render :json => raw_data}
      format.text { render :text => @log_data.map {|m| m['message']}.join("\n")}
    end
  end

  def time_stats
    load_time_stats
    render :json => @time_stats
  end

  def progress
    respond_to do |format|
      format.js
      format.json { render_json_ci_response(@deployment.present?, @deployment) }
    end
  end

  def preview
    flags = params.slice(:cost, :capacity).keys.select {|k| params[k] != 'false'}
    data, error = Transistor.deployment_plan_preview(@environment, *flags)
      if data
        render :json => data
      else
        render :json => {:errors => [error]}, :status => :internal_server_error
        return
      end
  end


  protected

  def read_only_request?
    action_name == 'status' || action_name == 'log_data' || super
  end

  private

  def find_deployment
    @deployment = Cms::Deployment.find(params[:id])
    render :text => 'not_found', :status => :not_found if @deployment.blank?
  end

  def get_log_data(ids)
    Daq.logs(ids.map {|id| {:id => id}})
  end

  def find_assembly_and_environment
    assembly_id = params[:assembly_id]
    return if assembly_id.blank?
    @assembly    = locate_assembly(assembly_id)

    env_id = params[:environment_id]
    return if env_id.blank?
    @environment = locate_environment(env_id, @assembly)
  end

  def load_deployment_states(step = nil)
    @deployment_rfc_cis_info = @deployment.new_record? ? {} : @deployment.rfc_cis(step).inject({}) do |states, rfc|
      states[rfc.rfcId] = {:recordId => rfc.dpmtRecordId, :state => rfc.dpmtRecordState, :comments => rfc.comments}
      states
    end
  end

  def load_ops_state_data
    @managed_via = Cms::Relation.all(:params => {:nsPath       => environment_bom_ns_path(@environment),
                                                 :recursive    => true,
                                                 :relationName => 'bom.ManagedVia'}).inject({}) do |h, r|
      h[r.fromCiId] = r
      h
    end

    @ops_states = Operations::Sensor.states((@rfc_cis.map(&:ciId) + @managed_via.values.map(&:toCiId)).uniq)
  end

  def find_open_bom_release
    @release = Cms::ReleaseBom.first(:params => {:nsPath => "#{environment_ns_path(@environment)}/bom", :releaseState => 'open'})
  end

  def load_bom_release_data
    load_deployment_states
    load_clouds_and_platforms

    @rfc_cis = @release.rfc_cis

    load_ops_state_data
  end

  def load_time_stats
    @time_stats = Search::WorkOrder.time_stats(@deployment)
  end

  def load_state_history
    @state_history = Cms::DeploymentStateChangeEvent.all(:params => {:deploymentId => @deployment.deploymentId})
  end

  def load_approvals
    @approvals = Cms::DeploymentApproval.all(:params => {:deploymentId => @deployment.deploymentId})
  end

  def load_clouds_and_platforms
    @clouds = Cms::Relation.all(:params => {:ciId              => @environment.ciId,
                                            :direction         => 'from',
                                            :relationShortName => 'Consumes',
                                            :targetClassName   => 'account.Cloud'}).to_map_with_value {|r| [r.toCiId, r.toCi]}

    @platforms = Cms::DjRelation.all(:params => {:ciId              => @environment.ciId,
                                                 :direction         => 'from',
                                                 :relationShortName => 'ComposedOf'}).to_map_with_value do |r|
      platform = r.toCi
      ["#{platform.ciName}/#{platform.ciAttributes.major_version}", platform]
    end

    platform_consumes = Cms::DjRelation.all(:params => {:nsPath            => environment_manifest_ns_path(@environment),
                                                        :fromClassName     => 'manifest.Platform',
                                                        :relationShortName => 'Consumes',
                                                        :recursive         => true})
    @primary_clouds = platform_consumes.
      select {|r| r.relationAttributes.adminstatus != 'offline' && r.relationAttributes.priority == '1'}.
      group_by {|r| r.nsPath.split('/', 6).last}
    @priority = platform_consumes.to_map_with_value {|r| ["#{r.nsPath.split('/', 6).last}/#{r.toCiId}", r.relationAttributes.priority]}
  end

  def check_for_override
    doc = MiscDoc.deployment_to_all_primary_check.document
    ns_path = environment_manifest_ns_path(@environment)
    return unless doc['*'] || doc.any? {|k, v| (ns_path.start_with?(k) || /#{k}/.match(ns_path)) && v}

    platforms = []
    find_open_bom_release unless @release
    load_bom_release_data unless @rfc_cis
    @rfc_cis.group_by {|rfc| rfc.nsPath.split('/bom/').last}.each do |p, rfcs|
      primary_clouds = @primary_clouds[p]
      if primary_clouds.size > 1
        cloud_map = primary_clouds.to_map(&:toCiId)
        deployment_order = rfcs.inject({}) do |h, rfc|
          cloud = cloud_map[rfc.ciName.split('-')[-2].to_i]
          h[cloud.relationAttributes.dpmt_order] = true if cloud
          h
        end
        platforms << p if deployment_order.size == 1
      end
    end
    @override = {:SIMULTANEOUS_DEPLOYMENT_TO_ALL_PRIMARY => {:platforms => platforms}} if platforms.present?
  end
end
