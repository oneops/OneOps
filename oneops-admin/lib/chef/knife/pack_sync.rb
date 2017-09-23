require 'cms'
require 'chef/knife/core/object_loader'
require 'fog'
require 'kramdown'

class Chef
  class Knife
    class UI
      def debug(message)
        stdout.puts message if @config[:verbosity] >= 2
      end
    end

    VISIBILITY_ALT_NS_TAG = 'enableForOrg'

    class PackSync < Chef::Knife
      banner "knife pack sync PACK (options)"

      option :all,
             :short => "-a",
             :long => "--all",
             :description => "Sync all packs"

      option :type,
             :short => "-t TYPE",
             :long => "--type TYPE",
             :description => "Limit to the specified type [iaas|platform]"

      option :register,
             :short => "-r REGISTER",
             :long => "--register REGISTER",
             :description => "Specify the source register name to use during sync"

      option :version,
             :short => "-v VERSION",
             :long => "--version VERSION",
             :description => "Specify the source register version to use during sync"

      option :cookbook_path,
             :short => "-o PATH:PATH",
             :long => "--cookbook-path PATH:PATH",
             :description => "A colon-separated path to look for cookbooks in",
             :proc => lambda { |o| o.split(":") }

      option :reload,
             :long => "--reload",
             :description => "Remove the current pack before uploading"

      option :semver,
             :long => "--semver",
             :description => "Creates new patch version for each change"


      option :msg,
             :short => '-m MSG',
             :long => '--msg MSG',
             :description => "Append a message to the comments"

      def packs_loader
        @packs_loader ||= Knife::Core::ObjectLoader.new(Chef::Pack, ui)
      end


      # safety measure: make sure no packs conflict in scope
      def validate_packs
        config[:pack_path] ||= Chef::Config[:pack_path]
        config[:version] ||= Chef::Config[:version]

        # keyed by group-name-version
        pack_map = {}

        config[:pack_path].each do |dir|

          pack_file_pattern = "#{dir}/*.rb"
          files = Dir.glob(pack_file_pattern)
          files.each do |file|
            pack = packs_loader.load_from("packs", file)
            key = "#{get_group(pack)}**#{pack.name.downcase}**#{pack.version.presence || config[:version].split('.').first}"
            if pack_map.has_key?(key)
              puts "error: conflict of pack group-name-version: #{key} #{file} to #{pack_map[key]}"
              puts "no packs loaded."
              exit 1
            else
              pack_map[key] = "#{file}"
            end
          end
        end
      end


      def run
        config[:pack_path] ||= Chef::Config[:pack_path]
        config[:register] ||= Chef::Config[:register]
        config[:version] ||= Chef::Config[:version]
        config[:semver] ||= ENV['SEMVER'].present?

        comments = "#{ENV['USER']}:#{$0}"
        comments += " #{config[:msg]}" if config[:msg]

        validate_packs

        if config[:all]
          config[:pack_path].each do |dir|
            pack_file_pattern = "#{dir}/*.rb"
            files = Dir.glob(pack_file_pattern)
            files.each do |file|
              unless upload_template_from_file(file, comments)
                ui.error("exiting")
                exit 1
              end
            end
          end
        elsif @name_args.present?
          @name_args.each do |pack|
            file = [pack,'rb'].join('.')
            unless upload_template_from_file(file, comments)
              ui.error("exiting")
              exit 1
            end
          end
        else
          ui.error "You must specify the pack name or use the --all option."
          exit 1
        end
      end

      def get_remote_dir
        unless @remote_dir
          conn       = get_connection
          env_bucket = Chef::Config[:environment_name]

          @remote_dir = conn.directories.get(env_bucket)
          if @remote_dir.nil?
            @remote_dir = conn.directories.create(:key => env_bucket)
            ui.debug "created #{env_bucket}"
          end
        end
        @remote_dir
      end

      def get_connection
        return @object_store_connection if @object_store_connection
        object_store_provider = Chef::Config[:object_store_provider]

        case object_store_provider
          when 'OpenStack'
            @object_store_connection = Fog::Storage.new({
                                                          :provider           => object_store_provider,
                                                          :openstack_username => Chef::Config[:object_store_user],
                                                          :openstack_api_key  => Chef::Config[:object_store_pass],
                                                          :openstack_auth_url => Chef::Config[:object_store_endpoint]
                                                        })
          when 'Local'
            @object_store_connection = Fog::Storage.new({
                                                          :provider   => object_store_provider,
                                                          :local_root => Chef::Config[:object_store_local_root]
                                                        })
          else
            raise Exception.new("unsupported object_store_provider: #{object_store_provider}")
        end

        return @object_store_connection
      end

      def gen_doc(ns,pack)
        if !Chef::Config.has_key?("object_store_provider") ||
            Chef::Config[:object_store_provider].nil? || Chef::Config[:object_store_provider].empty?
          ui.info "skipping doc - no object_store_provider"
          return
        end

        remote_dir = get_remote_dir
        initial_dir = Dir.pwd
        doc_dir = initial_dir + '/packs/doc'

        if File.directory? doc_dir
          Dir.chdir doc_dir
          ["#{pack.name}.md","#{pack.name}.png"].each do |file|
            remote_file = ns  + '/' + file
            local_file = doc_dir + '/' + file
            unless File.exists?(local_file)
              ui.warn "missing local file: #{local_file}"
              next
            end
            if file =~ /\.md$/
              content = Kramdown::Document.new(File.read(local_file)).to_html
              remote_file.gsub!(".md",".html")
              File.write(local_file.gsub(".md",".html"), content)
            else
              content = File.open(local_file)
            end
            # remove first slash in ns path
            remote_file = remote_file[1..-1]
            ui.info "doc: #{local_file}   =>   remote: #{remote_file}"
            obj = { :key => remote_file, :body => content }
            if remote_file =~ /\.html/
              obj['content_type'] = 'text/html'
            end

            file = remote_dir.files.create obj
          end
        end
        Dir.chdir initial_dir
      end


      # default to knife.rb config's register attr for backwards compat
      def get_group (pack)
        if !pack.group_id.empty?
          group_id = pack.group_id
        else
          group_id = Chef::Config[:register]
        end
        return group_id
      end

      def upload_template_from_file(file, comments)
        pack = packs_loader.load_from(Chef::Config[:pack_path], file)
        pack.name.downcase!
        if config[:semver] || pack.semver?
          return upload_template_from_file_ver_update(pack, comments)
        else
          return upload_template_from_file_no_verupdate(pack, comments)
        end
      end

      def upload_template_from_file_ver_update(pack, comments)
        if pack.ignore
          ui.info( "Ignoring pack #{pack.name} version #{pack.version}")
          return true
        end

        source = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs"
        return false unless ensure_path_exists(source)

        if config[:reload]
          ui.warn( "Reload option is no longer available in semver mode, all pack versions are immutable. If you need to force new patch version, force a change to the content of pack file (i.e. pack description) and do a pack sync.")
        end

        # If pack signature matches nothing to do.
        signature = check_pack_version_ver_update(pack)
        unless signature
          # Documentation could have been updated, reload it just in case.
          gen_doc("#{source}/#{pack.name}/#{pack.version}", pack)
          return true
        end

        Chef::Log.debug(pack.to_yaml)

        version_ci = setup_pack_version(pack, comments, signature)
        return false unless version_ci

        begin
          # Upload design template
          design_resources = pack.design_resources
          Chef::Log.debug([pack.name.capitalize, 'mgmt.catalog', design_resources, comments].to_yaml)
          ns = "#{source}/#{pack.name}/#{pack.version}"
          upload_template(ns, pack.name, 'mgmt.catalog', pack, '_default', design_resources, comments)
          gen_doc(ns, pack)

          # Upload manifest templates
          pack.environments.each do |name, env|
            environment_resources = pack.environment_resources(name)
            template_name = pack.name
            Chef::Log.debug([template_name, 'mgmt.manifest', environment_resources, comments].to_yaml)
            unless setup_mode(pack, name, comments)
              raise Exception.new("Unable to setup namespace for pack #{pack.name} version #{pack.version} environment mode #{name}")
            end
            upload_template(ns+"/#{name}", template_name, 'mgmt.manifest', pack, name, environment_resources, comments)
          end
        rescue Exception => e
          ui.error(e.message)
          ui.info('Attempting to clean up...')
          begin
            version_ci.destroy
          rescue Exception
            ui.warn("Failed to clean up pack #{pack.name} version #{pack.version}!")
          end
          raise e
        end

        ui.info("Uploaded pack #{pack.name} version #{pack.version}")
        return true
      end


      def upload_template_from_file_no_verupdate(pack, comments)
        source = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs"
        puts "source: #{source}"

        unless ensure_path_exists(source)
          return false
        end

        signature = Digest::MD5.hexdigest(pack.signature)

        # default to the global knife version if not specified
        version = config[:version].split(".").first
        if !pack.version.empty?
          version = pack.version.split(".").first
        end
        pack.version(version)

        if pack.ignore
          ui.info( "Ignoring pack #{pack.name} version #{pack.version}")
          return true
        end

        # If pack signature matches but reload option is not set - bail
        return true if !config[:reload] && check_pack_version_no_ver_update(pack, signature)

        ui.info( "Uploading pack #{pack.name}")
        Log.debug(pack.to_yaml)

        # First, check to see if anything from CMS need to
        # flip to pending_deletion
        fix_delta_cms(pack)

        # setup pack version namespace first
        pack_version = setup_pack_version(pack,comments,'')
        if pack_version.nil?
          ui.error( "Unable to setup namespace for pack #{pack.name} version #{pack.version}")
          return false
        end
        # Upload design template
        design_resources = pack.design_resources

        Chef::Log.debug([pack.name.capitalize,'mgmt.catalog',design_resources,comments].to_yaml)
        ns = "#{source}/#{pack.name}/#{pack.version}"
        upload_template(ns,pack.name,'mgmt.catalog',pack,'_default',design_resources,comments)
        gen_doc(ns,pack)
        # Upload manifest templates
        pack.environments.each do |name,env|
          environment_resources = pack.environment_resources(name)
          #template_name = [pack.name.capitalize,name].join('-')
          template_name = pack.name
          package = 'mgmt.manifest'
          Chef::Log.debug([template_name,'mgmt.manifest',environment_resources,comments].to_yaml)
          mode = setup_mode(pack,name,comments)
          if mode.nil?
            ui.error( "Unable to setup namespace for pack #{pack.name} version #{pack.version} environment mode #{name}")
            return false
          end
          upload_template(ns+"/#{name}",template_name,'mgmt.manifest',pack,name,environment_resources,comments)

        end
        ui.info( "Uploaded pack #{pack.name}")
        pack_version = setup_pack_version(pack,comments,signature)
        if pack_version.nil?
          ui.error( "Unable to setup namespace for pack #{pack.name} version #{pack.version}")
          return false
        end
        return true
      end

      private

      def parse_pack_relations(relations)
        relsHash = Hash.new()
        relations.each do |relation,relVal|
          if !relsHash.key?(relVal["relation_name"])
            relsHash[relVal['relation_name']] = [{"from_resource" => relVal["from_resource"], "to_resource" => relVal["to_resource"]}]
          else
            relsHash[relVal['relation_name']].push({"from_resource" => relVal["from_resource"], "to_resource" => relVal["to_resource"]})
          end
        end
        relsHash
      end

      def fix_delta_cms(pack)
        nsPath = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs/#{pack.name}/#{pack.version}"
        cmsEnvs = ['_default'] + Cms::Ci.all(:params => {:nsPath => nsPath, :ciClassName => 'mgmt.Mode'}).map(&:ciName)
        cmsEnvs.each do |env|
          relations = fix_rels_from_cms(pack, env)
          fix_ci_from_cms(pack, env,relations,cmsEnvs)
        end
      end

      def fix_rels_from_cms(pack, env = '_default')
        scope = (env == '_default') ? '' : "/#{env}"
        cms_rels = Cms::Relation.all(:params => {:nsPath        => "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs/#{pack.name}/#{pack.version}#{scope}",
                                                 :includeToCi   => true,
                                                 :includeFromCi => true})
        pack_rels = pack.relations
        targetRelations = []

        cms_rels.each do |r|
          new_state = nil
          fromCiName = r.fromCi.ciName
          toCiName = r.toCi.ciName
          relationShort = r.relationName.split('.').last
          key = "#{fromCiName}::#{relationShort.scan(/[A-Z][a-z]+/).join('_').downcase}::#{toCiName}"
          exists_in_pack = pack_rels.include?(key)
          # Search through resource to determine if relation exists or not
          unless exists_in_pack
            case relationShort
              when 'Payload'
                exists_in_pack = pack.resources[fromCiName] && pack.resources[fromCiName].include?('payloads') &&
                    pack.resources[fromCiName]['payloads'].include?(toCiName)
              when 'WatchedBy'
                exists_in_pack = pack.resources[fromCiName] && pack.resources[fromCiName].include?('monitors') &&
                    pack.resources[fromCiName]['monitors'].include?(toCiName)
              when 'Requires'
                exists_in_pack = pack.resources[fromCiName] && pack.resources[toCiName]
              when 'Entrypoint'
                if pack.entrypoints.include?(toCiName)
                  exists_in_pack = true
                else
                  exists_in_pack = false
                end
            end
          end

          if exists_in_pack
            targetRelations.push(toCiName) if !targetRelations.include?(toCiName)
          end

          if exists_in_pack && r.relationState == 'pending_deletion'
            new_state = 'default'
          elsif !exists_in_pack && r.relationState != 'pending_deletion'
            new_state = 'pending_deletion'
          end

          if new_state
            r.relationState = new_state
            if save(r)
              ui.debug("Successfuly updated ciRelationState to #{new_state} #{r.relationName} #{r.fromCi.ciName} <-> #{r.toCi.ciName} for #{env}")
            else
              ui.error("Failed to update ciRelationState to #{new_state} #{r.relationName} #{r.fromCi.ciName} <-> #{r.toCi.ciName} for #{env}")
            end
          end
        end
        targetRelations
      end
    end

    def fix_ci_from_cms(pack, env, relations,environments)
      scope = (env == '_default') ? '' : "/#{env}"
      cms_resources = Cms::Ci.all( :params => { :nsPath => "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs/#{pack.name}/#{pack.version}#{scope}"})

      pack_resources = pack.resources

      cms_resources.each do |resource|
        new_state = nil
        exists_in_pack = pack_resources.include?(resource.ciName) || relations.include?(resource.ciName) || environments.include?(resource.ciName)
        if exists_in_pack && resource.ciState == 'pending_deletion'
          new_state = 'default'
        elsif !exists_in_pack && resource.ciState != 'pending_deletion'
          new_state = 'pending_deletion'
        end
        if new_state
          resource.ciState = new_state
          if save(resource)
            ui.debug("Successfuly updated ciState to #{new_state} for #{resource.ciName} for #{env}")
          else
            ui.error("Failed to update ciState to #{new_state} for #{resource.ciName} for #{env}")
          end
        end
      end
    end

    def check_pack_version_ver_update(pack)
      all_versions = Cms::Ci.all(:params => {:nsPath       => "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs/#{pack.name}",
                                             :ciClassName  => 'mgmt.Version',
                                             :includeAltNs => VISIBILITY_ALT_NS_TAG})
      major, minor, patch = (pack.version.blank? ? config[:version] : pack.version).split('.')
      minor = '0' if minor.blank?

      # Need to filter version for the same major and find latest patch version for the same minor.
      latest_patch = nil
      latest_patch_number = -1
      versions = all_versions.select do |ci_v|
        split = ci_v.ciName.split('.')
        if major == split[0] && minor == split[1] && split[2].to_i > latest_patch_number
          latest_patch = ci_v
          latest_patch_number = split[2].to_i
        end
        major == split[0]
      end

      if versions.size > 0
        version_ci = latest_patch || versions.sort_by(&:ciName).last
        # Carry over 'enable' and 'visibility' from the latest patch or latest version overall.
        pack.enabled(version_ci.ciAttributes.attributes['enabled'] != 'false')
        pack.visibility(version_ci.altNs.attributes[VISIBILITY_ALT_NS_TAG])
      end

      if patch.present?
        # Check to make sure version does not already exist.
        version = "#{major}.#{minor}.#{patch}"
        if versions.find {|ci_v| ci_v.ciName == version}
          ui.warn("Pack #{pack.name} version #{pack.version} explicitly specified but it already exists, ignore it - will SKIP pack loading, but will try to update docs.")
          return nil
        else
          pack.version(version)
          ui.info("Pack #{pack.name} version #{pack.version} explicitly specified and it does not exist yet, will load.")
          return pack.signature
        end
      else
        ui.info("Pack #{pack.name} version #{pack.version} - patch version is not explicitly specified, continue with checking for latest patch version for it.")
      end

      if latest_patch
        pack.version(latest_patch.ciName)
        signature = Digest::MD5.hexdigest(pack.signature)
        if latest_patch.ciAttributes.attributes['commit'] == signature
          ui.info("Pack #{pack.name} latest patch version #{latest_patch.ciName} matches signature (#{signature}), will skip pack loading, but will try to update docs.")
          return nil
        else
          ui.warn("Pack #{pack.name} latest patch version #{latest_patch.ciName} signature is different from new pack signature #{signature}, will increment patch version and load.")
          pack.version("#{major}.#{minor}.#{latest_patch.ciName.split('.')[2].to_i + 1}")
          return pack.signature
        end
      else
        ui.info("No patches found for #{pack.name} version #{major}.#{minor}, start at patch 0 and load.")
        pack.version("#{major}.#{minor}.0")
        return pack.signature
      end
    end

    def check_pack_version_no_ver_update(pack,signature)
      source = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs"
      pack_version = Cms::Ci.first( :params => { :nsPath => "#{source}/#{pack.name}", :ciClassName => 'mgmt.Version', :ciName => pack.version })
      if pack_version.nil?
        ui.info( "Pack #{pack.name} version #{pack.version} not found")
        return false
      else
        if pack_version.ciAttributes.attributes.key?('commit') && pack_version.ciAttributes.commit == signature
          ui.info("Pack #{pack.name} version #{pack.version} matches signature #{signature}, use --reload to force load.")
          return true
        else
          ui.warn("Pack #{pack.name} version #{pack.version} signature is different from file signature #{signature}")
          return false
        end
      end
    end

    def setup_pack_version(pack,comments,signature)
      source = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs"
      pack_ci = Cms::Ci.first( :params => { :nsPath => "#{source}", :ciClassName => 'mgmt.Pack', :ciName => pack.name })
      if pack_ci.nil?
        ui.info( "Creating pack #{pack.name}")
        pack_ci = build('Cms::Ci',
                        :nsPath => "#{source}",
                        :ciClassName => 'mgmt.Pack',
                        :ciName => pack.name )
      else
        ui.info("Updating pack #{pack.name}")
      end

      pack_ci.comments = comments
      pack_ci.ciAttributes.pack_type = pack.type
      pack_ci.ciAttributes.description = pack.description
      pack_ci.ciAttributes.category = pack.category
      pack_ci.ciAttributes.owner = pack.owner

      Chef::Log.debug(pack_ci.to_json)
      if save(pack_ci)
        pack_version = Cms::Ci.first(:params => {:nsPath => "#{source}/#{pack.name}",
                                                 :ciClassName => 'mgmt.Version',
                                                 :ciName => pack.version})
        if pack_version.nil?
          ui.info( "Creating pack #{pack.name} version #{pack.version}")
          pack_version = build('Cms::Ci',
                               :nsPath       => "#{source}/#{pack.name}",
                               :ciClassName  => 'mgmt.Version',
                               :ciName       => pack.version,
                               :ciAttributes => {:enabled => pack.enabled},
                               :altNs        => {VISIBILITY_ALT_NS_TAG => pack.visibility})
        else
          ui.info("Updating pack #{pack.name} version #{pack.version}")
        end

        pack_version.comments = comments
        pack_version.ciAttributes.description = pack.description
        pack_version.ciAttributes.commit = signature

        Chef::Log.debug(pack_version.to_json)
        if save(pack_version)
          ui.info("Successfuly saved pack #{pack.name} version #{pack.version}")
          return pack_version
        else
          ui.error("Could not save pack #{pack.name} version #{pack.version}")
        end
      else
        ui.error("Could not save pack #{pack.name}")
      end
      return false
    end

    def setup_mode(pack,env,comments)
      source = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs"
      mode = Cms::Ci.first( :params => { :nsPath => "#{source}/#{pack.name}/#{pack.version}", :ciClassName => 'mgmt.Mode', :ciName => env })
      if mode.nil?
        ui.info( "Creating pack #{pack.name} version #{pack.version} environment mode #{env}")
        mode = build('Cms::Ci',
                     :nsPath      => "#{source}/#{pack.name}/#{pack.version}",
                     :ciClassName => 'mgmt.Mode',
                     :ciName      => env)
      else
        ui.info("Updating pack #{pack.name} version #{pack.version} environment mode #{env}")
      end

      mode.comments = comments
      mode.ciAttributes.description = pack.description

      Chef::Log.debug(mode.to_json)
      if save(mode)
        ui.info("Successfuly saved pack #{pack.name} version #{pack.version} environment mode #{env}")
        return mode
      else
        ui.error("Could not save pack #{pack.name} version #{pack.version} environment mode #{env}")
        return false
      end
    end

    def upload_template(nspath,template_name,package,pack,env,resources,comments)
      # create Platform first
      platform = upload_template_platform(nspath,template_name,package,pack,comments)
      if platform
        children = upload_template_children(nspath,platform,template_name,package,pack,env,resources,comments)
        upload_template_relations(nspath,platform,template_name,package,pack,env,resources,comments,children)
        upload_template_depends_on(nspath,pack,resources,children,env)
        upload_template_managed_via(nspath,pack,resources,children)
        upload_template_serviced_bys(nspath,pack,resources,children,platform,env)
        upload_template_entrypoint(nspath,pack,resources,children,platform,env)
        upload_template_serviced_by(nspath,pack,resources,children,platform,env)
        upload_template_monitors(nspath,pack,resources,children,platform,env,package)
        upload_template_payloads(nspath,pack,resources,children,platform,env)
        upload_template_procedures(nspath,pack,resources,children,platform,env)
        upload_template_variables(nspath,pack,package,platform,env)
        upload_template_policies(nspath,pack,package,platform,env)
      end
    end

    def upload_template_platform(nspath,template_name,package,pack,comments)
      ui.info( "============> #{pack.type}")
      ciClassName = [package,pack.type.capitalize].join('.')
      platform = Cms::Ci.first( :params => { :nsPath => nspath, :ciClassName => ciClassName, :ciName => template_name })
      if platform.nil?
        ui.info( "Creating #{ciClassName} for template #{template_name}")
        unless platform = build('Cms::Ci', :nsPath => nspath, :ciClassName => ciClassName, :ciName => template_name )
          ui.error("Could not build #{ciClassName}, skipping template #{template_name}")
          return false
        end
      else
        ui.debug("Updating #{ciClassName} for template #{template_name}")
      end

      #iterate over platform attributes and populate them with pack attributes from file
      platform.ciAttributes.attributes.each do |name, value|
        if pack.platform && pack.platform[:attributes] && pack.platform[:attributes].has_key?(name)
          platform.ciAttributes.send(name+'=', pack.platform[:attributes][name])
        end
      end

      platform.comments = comments
      platform.ciAttributes.description = pack.description
      platform.ciAttributes.source = get_group(pack)
      platform.ciAttributes.pack = pack.name.capitalize
      platform.ciAttributes.version = pack.version

      Chef::Log.debug("SERVICES: #{pack.services.inspect}")

      platform.ciAttributes.services = pack.services.to_json if platform.ciAttributes.respond_to?('services')

      Chef::Log.debug(platform.to_json)
      if save(platform)
        ui.debug("Successfuly saved #{ciClassName} for template #{template_name}")
        return platform
      else
        ui.error("Could not save #{ciClassName}, skipping template #{template_name}")
        return false
      end
    end

    def upload_template_children(nspath,platform,template_name,package,pack,env,resources,comments)
      children = Hash.new
      relations = Cms::Relation.all( :params => {  :ciId => platform.id,
                                                   :nsPath => nspath,
                                                   :direction => 'from',
                                                   :relationShortName => 'Requires',
                                                   :includeToCi => true
      })

      resources.each do |resource_name,resource|
        # make sure last / short class is capitalized
        if resource[:cookbook].include? "."
          classParts = resource[:cookbook].split(".")
          lastIndex = classParts.size-1
          classParts[lastIndex] = classParts[lastIndex].capitalize
          ciClassName = classParts.join(".")
        else
          ciClassName = resource[:cookbook].capitalize
        end

        if resource[:source]
          ciClassName = [ package, resource[:source], ciClassName ].join('.')
        else
          ciClassName = [ package, ciClassName ].join('.')
        end

        relation = relations.find { |r| r.toCi.ciName == resource_name && r.toCi.ciClassName == ciClassName }

        if relation.nil?
          ui.info( "Creating resource #{resource_name} for #{template_name}")
          relation = build('Cms::Relation',
                           :relationName => 'mgmt.Requires',
                           :nsPath => nspath,
                           :fromCiId => platform.id
          )
          ci = Cms::Ci.first( :params => { :nsPath => nspath, :ciClassName => ciClassName, :ciName => resource_name })
          if ci.nil?
            relation.toCiId = 0
            relation.toCi = build('Cms::Ci',
                                  :nsPath => nspath,
                                  :ciClassName => ciClassName,
                                  :ciName => resource_name
            )
          else
            relation.toCiId = ci.id
            Log.debug(relation.inspect)
            # if relation is missing, but ci is present, save the relation only first
            if save(relation)
              ui.debug("Successfuly saved resource #{resource_name} for template #{template_name}")
              relation = Cms::Relation.find(relation.id, :params => {  :nsPath => nspath, :includeToCi => true } )
            else
              ui.error("Could not save resource #{resource_name}, skipping it")
            end
          end
          unless relation
            ui.error("Could not build resource #{resource_name}, skipping it")
            next;
          end

        else
          ui.debug("Updating resource #{resource_name} for template #{template_name}")
        end

        Log.debug('PRE-ATTRIBUTE: ' + relation.inspect)

        relation.comments = comments
        relation.toCi.comments = comments

        # default value for template attribute is the resource name
        relation.relationAttributes.template = resource_name
        unless resource[:requires].nil?
          # requires relation attributes
          relation.relationAttributes.attributes.each do |name,value|
            if resource[:requires][name]
              relation.relationAttributes.send(name+'=',resource[:requires][name])
            end
          end
          # target class attributes
          relation.toCi.ciAttributes.attributes.each do |name,value|
            # old way - remove whn all packs cleaned up
            if pack.default_attributes[resource_name] && pack.default_attributes[resource_name].has_key?(name)
              relation.toCi.ciAttributes.send(name+'=',pack.default_attributes[resource_name][name])
            end
            # new way of default attribute definition in the resource
            if resource[:attributes] && resource[:attributes].has_key?(name)
              relation.toCi.ciAttributes.send(name+'=',resource[:attributes][name])
            end
          end
        end

        Log.debug(relation.inspect)
        if save(relation)
          ui.debug("Successfuly saved resource #{resource_name} for template #{template_name}")
          children[resource_name] = relation.toCi.ciId
        else
          ui.error("Could not save resource #{resource_name}, skipping it")
        end
      end
      return children
    end

    def upload_template_relations(nspath,platform,template_name,package,pack,env,resources,comments,children)
      pack.environment_relations(env).each do |relation_name,relation|
        relationName = "mgmt.#{(env == '_default') ? 'catalog' : 'manifest'}.#{relation[:relation_name]}"
        relation_list = Cms::Relation.all(:params => {:nsPath       => nspath,
                                                      :relationName => relationName})
        if children[relation[:from_resource]].nil?
          ui.error("Could not save relation #{relation[:relation_name]} between #{relation[:from_resource]} (missing resource) and #{relation[:to_resource]} in #{env}")
        elsif children[relation[:to_resource]].nil?
          ui.error("Could not save relation #{relation[:relation_name]} between #{relation[:from_resource]} and #{relation[:to_resource]} in #{env}")
        else
          relation_new = relation_list.find {|d| d.fromCiId == children[relation[:from_resource]] && d.toCiId == children[relation[:to_resource]]}
          if relation_new.nil?
            ui.info( "Creating relation #{relation[:relation_name]} between #{relation[:from_resource]} and #{relation[:to_resource]}")
            relation_new = build('Cms::Relation',
                                 :relationName => relationName,
                                 :nsPath => nspath,
                                 :fromCiId => children[relation[:from_resource]],
                                 :toCiId => children[relation[:to_resource]]
            )
          else
            ui.debug( "Updating relation #{relation[:relation_name]} between #{relation[:from_resource]} and #{relation[:to_resource]}")
          end

          relation_new.relationAttributes.attributes.each do |name,value|
            if relation[:attributes][name]
              relation_new.relationAttributes.send(name+'=',relation[:attributes][name])
            end
          end
          Log.debug(relation_new.to_yaml)
          if save(relation_new)
            ui.debug("Successfuly saved relation #{relation[:relation_name]} between #{relation[:from_resource]} and #{relation[:to_resource]}")
          else
            ui.error("Could not save relation #{relation[:relation_name]} between #{relation[:from_resource]} and #{relation[:to_resource]}")
          end
        end
      end
    end

    def upload_template_depends_on(nspath,pack,resources,children,env)
      relationName = "mgmt.#{(env == '_default') ? 'catalog' : 'manifest'}.DependsOn"
      depends_on_list = Cms::Relation.all(:params => {:nsPath       => nspath,
                                                      :relationName => relationName})
      resources.each do |resource_name,resource|
        unless pack.depends_on[resource_name].nil?
          pack.depends_on[resource_name].each do |do_class,attributes|
            next unless children[do_class] # skip if the target depends_on is not in this mode/env
            depends_on = depends_on_list.find {|d| d.fromCiId == children[resource_name]  && d.toCiId == children[do_class]}
            if depends_on.nil?
              ui.info( "Creating depends on between #{resource_name} and #{do_class}")
              depends_on = build('Cms::Relation',
                                 :relationName => relationName,
                                 :nsPath => nspath,
                                 :fromCiId => children[resource_name],
                                 :toCiId => children[do_class]
              )
            else
              ui.debug( "Updating depends on between #{resource_name} and #{do_class}")
            end

            depends_on.relationAttributes.attributes.each do |name,value|
              if pack.depends_on[resource_name][do_class][name]
                depends_on.relationAttributes.send(name+'=',pack.depends_on[resource_name][do_class][name])
              end
            end
            Log.debug(depends_on.to_yaml)
            if save(depends_on)
              ui.debug("Successfuly saved depends on between #{resource_name} and #{do_class}")
            else
              ui.error("Could not save depends on between #{resource_name} and #{do_class} in #{nspath}, skipping it")
            end
          end
        end
      end
    end

    def upload_template_managed_via(nspath,pack,resources,children)
      resources.each do |resource_name,resource|
        unless pack.managed_via[resource_name].nil?
          pack.managed_via[resource_name].each do |mv_class,attributes|
            relationName = 'mgmt.manifest.ManagedVia'
            managed_via_list = Cms::Relation.all( :params => {  :ciId => children[resource_name],
                                                                :nsPath => nspath,
                                                                :direction => 'from',
                                                                :relationName => relationName
            })
            managed_via = managed_via_list.select {|d| d.toCi.ciId == children[mv_class]}.first unless managed_via_list.nil?
            if managed_via.nil?
              ui.info( "Creating managed via between #{resource_name} and #{mv_class}")
              managed_via = build('Cms::Relation',
                                  :relationName => relationName,
                                  :nsPath => nspath,
                                  :fromCiId => children[resource_name],
                                  :toCiId => children[mv_class]
              )
            else
              ui.debug( "Updating managed via between #{resource_name} and #{mv_class}")
            end

            managed_via.relationAttributes.attributes.each do |name,value|
              if pack.managed_via[resource_name][mv_class][name]
                managed_via.relationAttributes.send(name+'=',pack.managed_via[resource_name][mv_class][name])
              end
            end
            Log.debug(managed_via.to_yaml)
            if save(managed_via)
              ui.debug("Successfuly saved managed via between #{resource_name} and #{mv_class}")
            else
              ui.error("Could not save managed via between #{resource_name} and #{mv_class}, skipping it")
            end
          end
        end
      end
    end

    def upload_template_serviced_bys(nspath,pack,resources,children,platform,env)

      source = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs"
      relationName = 'mgmt.manifest.ServicedBy'
      serviced_by_list = Cms::Relation.all( :params => {  :ciId => platform.ciId,
                                                          :nsPath => nspath,
                                                          :direction => 'from',
                                                          :relationName => relationName
      })
      pack.environment_serviced_bys(env).each do |iaas_name,iaas_pack|
        serviced_by = serviced_by_list.select {|d| d.toCi.pack == iaas_pack[:pack] && d.toCi.version == iaas_pack[:version] }.first unless serviced_by_list.nil?
        if serviced_by.nil?
          ui.info( "Creating serviced by between platform and #{iaas_pack[:pack]} version #{iaas_pack[:version]}")
          iaas_path = "#{source}/#{iaas_pack[:pack]}/#{iaas_pack[:version]}/#{env}"
          iaas = Cms::Ci.all( :params=> { :nsPath => iaas_path, :ciName => iaas_pack[:pack], :ciClassName => 'mgmt.manifest.Iaas' } ).first
          if iaas.nil?
            ui.error("Could not find target Iaas pack for serviced by between platform and #{iaas_pack[:pack]} version #{iaas_pack[:version]} in #{iaas_path}, skipping it")
          else
            serviced_by = build('Cms::Relation',
                                :relationName => relationName,
                                :nsPath => nspath,
                                :fromCiId => platform.ciId,
                                :toCiId => iaas.ciId
            )
            Log.debug(serviced_by.to_yaml)
            if save(serviced_by)
              ui.debug("Successfuly saved serviced by between platform and #{iaas_pack[:pack]} version #{iaas_pack[:version]}")
            else
              ui.error("Could not save serviced by between platform and #{iaas_pack[:pack]} version #{iaas_pack[:version]}, skipping it")
            end
          end
        else
          ui.info( "Existing serviced by between platform and #{iaas_pack[:pack]} version #{iaas_pack[:version]}")
        end
        #ui.info("SERVICED_BY: #{iaas_pack.inspect}")
      end
    end

    def upload_template_entrypoint(nspath,pack,resources,children,platform,env)
      resources.each do |resource_name,resource|
        unless pack.environment_entrypoints(env)[resource_name].nil?
          relationName = 'mgmt.Entrypoint'
          entrypoint_list = Cms::Relation.all( :params => {  :ciId => platform.ciId,
                                                             :nsPath => nspath,
                                                             :direction => 'from',
                                                             :relationName => relationName
          })
          entrypoint = entrypoint_list.select {|d| d.toCi.ciId == children[resource_name]}.first unless entrypoint_list.nil?
          if entrypoint.nil?
            ui.info( "Creating entrypoint between platform and #{resource_name}")
            entrypoint = build('Cms::Relation',
                               :relationName => relationName,
                               :nsPath => nspath,
                               :fromCiId => platform.ciId,
                               :toCiId => children[resource_name]
            )
          else
            ui.debug("Updating entrypoint between platform and #{resource_name}")
          end

          entrypoint.relationAttributes.attributes.each do |name,value|
            if pack.entrypoints[resource_name]['attributes'][name]
              entrypoint.relationAttributes.send(name+'=',pack.entrypoints[resource_name]['attributes'][name])
            end
          end
          Log.debug(entrypoint.to_yaml)
          if save(entrypoint)
            ui.debug("Successfuly saved entrypoint between platform and #{resource_name}")
          else
            ui.error("Could not save entrypoint between platform and #{resource_name}, skipping it")
          end
        end
      end
    end

    def upload_template_serviced_by(nspath,pack,resources,children,platform,env)

      source = "#{Chef::Config[:nspath]}/#{get_group(pack)}/packs"
      resources.each do |resource_name,resource|
        next if resource[:serviced_by].nil?
        relationName = 'mgmt.manifest.ServicedBy'
        serviced_by_list = Cms::Relation.all( :params => {  :ciId => children[resource_name],
                                                            :nsPath => nspath,
                                                            :direction => 'from',
                                                            :relationName => relationName
        })
        resource[:serviced_by].each do |iaas_pack|
          serviced_by = serviced_by_list.select {|d| d.toCi.pack == iaas_pack[:pack] && d.toCi.version == iaas_pack[:version] }.first unless serviced_by_list.nil?
          if serviced_by.nil?
            ui.info( "Creating serviced by between #{resource_name} and #{iaas_pack[:pack]} version #{iaas_pack[:version]}")
            iaas_path = "#{source}/#{iaas_pack[:pack]}/#{iaas_pack[:version]}/#{env}"
            iaas = Cms::Ci.all( :params=> { :nsPath => iaas_path, :ciName => iaas_pack[:pack], :ciClassName => 'mgmt.manifest.Iaas' } ).first
            if iaas.nil?
              ui.error("Could not find target Iaas pack for serviced by between #{resource_name} and #{iaas_pack[:pack]} version #{iaas_pack[:version]} in #{iaas_path}, skipping it")
            else
              serviced_by = build('Cms::Relation',
                                  :relationName => relationName,
                                  :nsPath => nspath,
                                  :fromCiId => children[resource_name],
                                  :toCiId => iaas.ciId
              )
              Log.debug(serviced_by.to_yaml)
              if save(serviced_by)
                ui.debug("Successfuly saved serviced by between #{resource_name} and #{iaas_pack[:pack]} version #{iaas_pack[:version]}")
              else
                ui.error("Could not save serviced by between #{resource_name} and #{iaas_pack[:pack]} version #{iaas_pack[:version]}, skipping it")
              end
            end
          else
            ui.info( "Existing serviced by between #{resource_name} and #{iaas_pack[:pack]} version #{iaas_pack[:version]}")
          end

        end
      end
    end

    def upload_template_monitors(nspath,pack,resources,children,platform,env,package)

      relationName = "#{package}.WatchedBy"
      ciClassName = "#{package}.Monitor"
      relations = Cms::Relation.all(:params => {
          :nsPath            => nspath,
          :relationName => relationName,
          :includeToCi       => true})

      resources.each do |resource_name,resource|
        next if resource[:monitors].nil?
        resource[:monitors].each do |monitor_name,monitor|

          relation = relations.find {|r| r.fromCiId == children[resource_name] && r.toCi.ciName == monitor_name}

          if relation.nil?
            ui.info( "Creating monitor #{monitor_name} for #{resource_name}")
            relation = build('Cms::Relation',
                             :relationName => relationName,
                             :nsPath => nspath,
                             :fromCiId => children[resource_name]
            )
            ci = Cms::Ci.first( :params => { :nsPath => nspath, :ciClassName => ciClassName, :ciName => monitor_name })
            if ci.nil?
              relation.toCiId = 0
              relation.toCi = build('Cms::Ci',
                                    :nsPath => nspath,
                                    :ciClassName => ciClassName,
                                    :ciName => monitor_name
              )
            else
              relation.toCiId = ci.id
              Log.debug(relation.inspect)

              # if relation is missing, but ci is present, save the relation only first
              if save(relation)
                ui.info("Successfuly saved monitor #{monitor_name} for #{resource_name} in #{package}")
                relation = Cms::Relation.find(relation.id, :params => {  :nsPath => nspath, :includeToCi => true } )
              else
                ui.error("Could not save monitor #{monitor_name} for #{resource_name}, skipping it")
              end
            end
            unless relation
              ui.error("Could not build monitor #{monitor_name} for #{resource_name}, skipping it")
              next;
            end
          else
            ui.info("Updating monitor #{monitor_name} for #{resource_name} in #{package}")
          end

          # qpath attributes
          relation.toCi.ciAttributes.attributes.each do |name,value|
            if monitor[name]
              monitor[name] = monitor[name].to_json if (monitor[name].is_a?(Hash))
              relation.toCi.ciAttributes.send(name+'=',monitor[name])
            end
          end

          Log.debug(relation.inspect)
          if save(relation)
            ui.info("Successfuly saved monitor #{monitor_name} for #{resource_name} in #{package}")
          else
            ui.error("Could not save monitor #{monitor_name} for #{resource_name}, skipping it")
          end

        end
      end
    end

    def upload_template_payloads(nspath,pack,resources,children,platform,env)
      resources.each do |resource_name,resource|
        next if resource[:payloads].nil?
        resource[:payloads].each do |payload_name,payload|
          relationName = 'mgmt.manifest.Payload'
          ciClassName = 'mgmt.manifest.Qpath'
          relation = Cms::Relation.all( :params => {  :ciId => children[resource_name],
                                                      :nsPath => nspath,
                                                      :direction => 'from',
                                                      :relationName => relationName,
                                                      :targetClassName => ciClassName,
                                                      :includeToCi => true
          }).select { |r| r.toCi.ciName == payload_name }.first
          if relation.nil?
            ui.info( "Creating payload #{payload_name} for #{resource_name}")
            relation = build('Cms::Relation',
                             :relationName => relationName,
                             :nsPath => nspath,
                             :fromCiId => children[resource_name]
            )
            ci = Cms::Ci.first(:params => {:nsPath => nspath, :ciClassName => ciClassName, :ciName => payload_name})
            if ci.nil?
              relation.toCiId = 0
              relation.toCi = build('Cms::Ci',
                                    :nsPath => nspath,
                                    :ciClassName => ciClassName,
                                    :ciName => payload_name
              )
            else
              relation.toCiId = ci.id
              Log.debug(relation.inspect)
              # if relation is missing, but ci is present, save the relation only first
              if save(relation)
                ui.debug("Successfuly saved payload #{payload_name} for #{resource_name}")
                relation = Cms::Relation.find(relation.id, :params => {  :nsPath => nspath, :includeToCi => true } )
              else
                ui.error("Could not save payload #{payload_name} for #{resource_name}, skipping it")
              end
            end
            unless relation
              ui.error("Could not build payload #{payload_name} for #{resource_name}, skipping it")
              next;
            end
          else
            ui.debug("Updating payload #{payload_name} for #{resource_name}")
          end

          # qpath attributes
          relation.toCi.ciAttributes.attributes.each do |name,value|
            if payload[name]
              relation.toCi.ciAttributes.send(name+'=',payload[name])
            end
          end

          Log.debug(relation.inspect)
          if save(relation)
            ui.debug("Successfuly saved payload #{payload_name} for #{resource_name}")
          else
            ui.error("Could not save payload #{payload_name} for #{resource_name}, skipping it")
          end

        end
      end
    end

    def upload_template_procedures(nspath,pack,resources,children,platform,env)
      pack.environment_procedures(env).each do |procedure_name,procedure_attributes|
        relationName = 'mgmt.manifest.ControlledBy'
        ciClassName = 'mgmt.manifest.Procedure'
        relation = Cms::Relation.all( :params => {  :ciId => platform.id,
                                                    :nsPath => nspath,
                                                    :direction => 'from',
                                                    :relationName => relationName,
                                                    :targetClassName => ciClassName,
                                                    :includeToCi => true
        }).select { |r| r.toCi.ciName == procedure_name }.first
        if relation.nil?
          ui.info( "Creating procedure #{procedure_name} for environment #{env}")
          relation = build('Cms::Relation',
                           :relationName => relationName,
                           :nsPath => nspath,
                           :fromCiId => platform.id
          )
          ci = Cms::Ci.first( :params => { :nsPath => nspath, :ciClassName => ciClassName, :ciName => procedure_name })
          if ci.nil?
            relation.toCiId = 0
            relation.toCi = build('Cms::Ci',
                                  :nsPath => nspath,
                                  :ciClassName => ciClassName,
                                  :ciName => procedure_name
            )
          else
            relation.toCiId = ci.id

            # if relation is missing, but ci is present, save the relation only first
            if save(relation)
              ui.debug("Successfuly saved procedure #{procedure_name} for environment #{env}")
              relation = Cms::Relation.find(relation.id, :params => {  :nsPath => nspath, :includeToCi => true } )
            else
              ui.error("Could not save procedure #{procedure_name} for environment #{env}, skipping it")
            end
          end
          unless relation
            ui.error("Could not build procedure #{procedure_name} for environment #{env}, skipping it")
            next;
          end
        else
          ui.debug("Updating procedure #{procedure_name} for environment #{env}")
        end

        # procedure attributes
        relation.toCi.ciAttributes.attributes.each do |name,value|
          if procedure_attributes[name]
            if name == 'arguments'
              procedure_attributes[name] = procedure_attributes[name].to_json if (procedure_attributes[name].is_a?(Hash))
            end
            relation.toCi.ciAttributes.send(name+'=',procedure_attributes[name])
          end
        end

        Log.debug(relation.inspect)
        if save(relation)
          ui.debug("Successfuly saved procedure #{procedure_name} for environment #{env}")
        else
          ui.error("Could not save procedure #{procedure_name} for environment #{env}, skipping it")
        end

      end
    end

    def upload_template_variables(nspath,pack,package,platform,env)
      pack.environment_variables(env).each do |variable_name,variable_attributes|
        relationName = "#{package}.ValueFor"
        ciClassName = "#{package}.Localvar"
        relation = Cms::Relation.all( :params => {  :ciId => platform.id,
                                                    :nsPath => nspath,
                                                    :direction => 'to',
                                                    :relationName => relationName,
                                                    :targetClassName => ciClassName,
                                                    :includeFromCi => true
        }).select { |r| r.fromCi.ciName == variable_name }.first
        if relation.nil?
          ui.info( "Creating variable #{variable_name} for environment #{env}")
          relation = build('Cms::Relation',
                           :relationName => relationName,
                           :nsPath => nspath,
                           :toCiId => platform.id
          )
          ci = Cms::Ci.first( :params => { :nsPath => nspath, :ciClassName => ciClassName, :ciName => variable_name })
          if ci.nil?
            relation.fromCiId = 0
            relation.fromCi = build('Cms::Ci',
                                    :nsPath => nspath,
                                    :ciClassName => ciClassName,
                                    :ciName => variable_name
            )
          else
            relation.fromCiId = ci.id
            Log.debug(relation.inspect)
            # if relation is missing, but ci is present, save the relation only first
            if save(relation)
              ui.debug("Successfuly saved variable #{variable_name} for environment #{env}")
              relation = Cms::Relation.find(relation.id, :params => {  :nsPath => nspath, :includeFromCi => true } )
            else
              ui.error("Could not save variable #{variable_name} for environment #{env}, skipping it")
            end
          end
          unless relation
            ui.error("Could not build variable #{variable_name} for environment #{env}, skipping it")
            next;
          end
        else
          ui.debug("Updating variable #{variable_name} for environment #{env}")
        end

        # procedure attributes
        relation.fromCi.ciAttributes.attributes.each do |name,value|
          if variable_attributes[name]
            relation.fromCi.ciAttributes.send(name+'=',variable_attributes[name])
          end
        end

        Log.debug(relation.inspect)
        if save(relation)
          ui.debug("Successfuly saved variable #{variable_name} for environment #{env}")
        else
          ui.error("Could not save variable #{variable_name} for environment #{env}, skipping it")
        end

      end
    end

    def upload_template_policies(nspath,pack,package,platform,env)
      pack.environment_policies(env).each do |policy_name,policy_attributes|
        ciClassName = "#{package}.Policy"

        ci = Cms::Ci.first( :params => { :nsPath => nspath, :ciClassName => ciClassName, :ciName => policy_name })

        if ci.nil?
          ci = build('Cms::Ci',
                     :nsPath => nspath,
                     :ciClassName => ciClassName,
                     :ciName => policy_name)

          if save(ci)
            ui.debug("Successfuly saved policy #{policy_name} for environment #{env} and #{pack}")
          else
            ui.error("Could not save policy #{policy_name} for environment #{env}, skipping it")
          end
        end

        # policy ci attributes
        ci.ciAttributes.attributes.each do |name,value|
          if policy_attributes[name]
            ci.ciAttributes.send(name+'=',policy_attributes[name])
          end
        end

        Log.debug(ci.inspect)
        if save(ci)
          ui.debug("Successfuly saved policy #{policy_name} attributes for environment #{env} and #{pack}")
        else
          ui.error("Could not save policy #{policy_name} attributes for environment #{env} and #{pack}, skipping it")
        end

      end

    end

    def ensure_path_exists(nspath)
      ns = Cms::Namespace.all( :params => { :nsPath => nspath } ).first
      if ns.nil?
        ui.error("Can't find namespace #{nspath}. Please register your source first with the register command")
      end
      return ns
    end

    def save(object)
      begin
        ok = object.save
      rescue Exception => e
        Log.debug(e.response.read_body)
      end
      ok ? object : false
    end

    def destroy(object)
      begin
        ok = object.destroy
      rescue Exception => e
        Log.debug(e.response.read_body)
      end
      ok ? object : false
    end

    def build(klass, options)
      begin
        object = klass.constantize.build(options)
      rescue Exception => e
        Log.debug(e.response.read_body)
      end
      object ? object : false
    end
  end
end
