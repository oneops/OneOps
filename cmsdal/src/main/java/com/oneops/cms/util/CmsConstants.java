/*******************************************************************************
 *  
 *   Copyright 2015 Walmart, Inc.
 *  
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *  
 *       http://www.apache.org/licenses/LICENSE-2.0
 *  
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *  
 *******************************************************************************/
package com.oneops.cms.util;

public final class CmsConstants {

	//Cloud active state
	public static final String CLOUD_STATE_ACTIVE = "active";
	public static final String CLOUD_STATE_OFFLINE = "offline";

	public static final String CI_STATE_PENDING_DELETION = "pending_deletion";

	public static final String SECURED_ATTRIBUTE = "IS_SECURED";
	public static final String ENCRYPTED_ATTR_VALUE = "ENC_VALUE";
	
	public static final String REQUEST_ENQUE_TS = "requestEnqueTS";
	public static final String REQUEST_DEQUE_TS = "requestDequeTS";
	public static final String RESPONSE_ENQUE_TS = "responseEnqueTS";
	public static final String RESPONSE_DEQUE_TS = "responseDequeTS";
	public static final String QUEUE_TIME = "queueTime";
	public static final String CLOSE_TIME = "closeTime";
	public static final String EXECUTION_TIME = "executionTime";
	public static final String LOCAL_WAIT_TIME = "localWaitTime";
	public static final String TOTAL_TIME = "totalTime";
	public static final String INDUCTOR_LOCAL_RETRIES = "inductorLocalRetries";
	public static final String INDUCTOR_RETRIES = "inductorRetries";
	public static final String INDUCTOR_RSYNC_TIME = "rsyncTime";
	public static final String SEARCH_TS_PATTERN =  "yyyy-MM-dd'T'HH:mm:ss.SSS";
	
	//starting to put some relation constants 
	public static final String ENTRYPOINT = "Entrypoint";
	//base relations
	public static final String BASE_REALIZED_AS = "base.RealizedAs";
	public static final String BASE_COMPLIES_WITH = "base.CompliesWith";
	public static final String DEPLOYED_TO = "base.DeployedTo";
	public static final String BASE_PROVIDES = "base.Provides";
	public static final String BASE_PLACED_IN = "base.PlacedIn";
	public static final String BASE_CONSUMES = "base.Consumes";
	public static final String BASE_REQUIRES = "base.Requires";
	public static final String BASE_ENTRYPOINT = "base.Entrypoint";

	//catalog relations
	public static final String CATALOG_DEPENDS_ON = "catalog.DependsOn";
	public static final String CATALOG_ESCORTED_BY = "catalog.EscortedBy";
	public static final String CATALOG_WATCHED_BY = "catalog.WatchedBy";
	public static final String CATALOG_VALUE_FOR = "catalog.ValueFor";

	//manifest relations
	public static final String MANIFEST_WATCHED_BY = "manifest.WatchedBy";
	public static final String MANIFEST_REQUIRES = "manifest.Requires";
	public static final String MANIFEST_ESCORTED_BY = "manifest.EscortedBy";
	public static final String MANIFEST_LOGGED_BY = "manifest.LoggedBy";

	//mgmt relations
	public static final String MGMT_CATALOG_WATCHEDBY = "mgmt.catalog.WatchedBy";
	public static final String MGMT_CATALOG_DEPENDS_ON = "mgmt.catalog.DependsOn";
	public static final String MGMT_CATALOG_VALUE_FOR = "mgmt.catalog.ValueFor";

	//attributes
	public static final String ATTR_VALUE_TYPE_DF = "df";
	public static final String ATTR_NAME_ENABLED = "enabled";
	public static final String ATTR_NAME_AUTO_COMPLY = "autocomply";
	public static final int SECONDARY_CLOUD_STATUS = 2;
	public static final int PRIMARY_CLOUD_STATUS = 1;
	public static final String ATTR_NAME_ADMINSTATUS = "adminstatus";
	public static final String ATTR_RUN_ON = "run_on";
	public static final String ATTR_RUN_ON_ACTION = "run_on_action";
	public static final String ATTR_NAME_SOURCE = "source";
	public static final String ATTR_SOURCE_VALUE_DESIGN = "design";
	public static final String ATTR_OWNER_VALUE_DESIGN = "design";
	public static final String MONITOR_CUSTOM_ATTR = "custom";

	//class-names
	//account
	public static final String ACCOUNT_CLOUD_CLASS = "account.Cloud";

	//mgmt
	public static final String MGMT_PACK_VERSION_CLASS = "mgmt.Version";
	public static final String MGMT_CATALOG_PLATFORM_CLASS = "mgmt.catalog.Platform";
	public static final String MGMT_CATALOG_MONITOR_CLASS = "mgmt.catalog.Monitor";
	public static final String MGMT_CATALOG_LOCALVAR_CLASS = "mgmt.catalog.Localvar";

	//catalog
	public static final String CATALOG_LOCALVAR_CLASS = "catalog.Localvar";

	//manifest
	public static final String MONITOR_CLASS = "manifest.Monitor";
	public static final String ZONE_CLASS = "cloud.Zone";
	public static final String CLOUD_CLASS = "account.Cloud";
	public static final String MANIFEST_LOG_CLASS = "manifest.Log";
	public static final String MANIFEST_ATTACHMENT_CLASS = "manifest.Attachment";

	public static final String CATALOG_MONITOR_CLASS = "catalog.Monitor";

	public static final String BOM = "bom";
	public static final String MANIFEST = "manifest";
	public static final String CATALOG = "catalog";

	public static final String BOM_MANAGED_VIA = "bom.ManagedVia";
	public static final String BOM_DEPENDS_ON = "bom.DependsOn";

	public static final String CLOUDSERVICEPREFIX = "cloud.service";
	public static final String MANAGED_VIA = "ManagedVia";
	public static final String DEPENDS_ON = "DependsOn";
	public static final String SECURED_BY = "SecuredBy";
	public static final String SERVICED_BY = "ServicedBy";
	public static final String REALIZED_AS = "RealizedAs";

	public static final String ESCORTED_BY = "EscortedBy";
}
