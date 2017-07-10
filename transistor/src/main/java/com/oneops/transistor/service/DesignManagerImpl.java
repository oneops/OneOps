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
package com.oneops.transistor.service;

import com.oneops.cms.cm.domain.CmsCI;
import com.oneops.cms.dj.domain.CmsRfcCI;
import com.oneops.cms.simple.domain.CmsRfcRelationSimple;
import com.oneops.transistor.domain.CatalogExport;
import com.oneops.transistor.export.domain.DesignExportSimple;
import com.oneops.transistor.export.domain.EnvironmentExportSimple;

import java.util.List;
import java.util.Map;

public class DesignManagerImpl implements DesignManager {

	private DesignRfcProcessor designRfcProcessor;
	private DesignExportProcessor designExpProcessor;
	private CatalogProcessor catalogProcessor;
	private PackRefreshProcessor packRefreshProcessor;
	private PackUpdateProcessor packUpdateProcessor;
	private EnvironmentExportProcessor environmentExpProcessor;

	public void setEnvironmentExpProcessor(EnvironmentExportProcessor environmentExpProcessor) {
		this.environmentExpProcessor = environmentExpProcessor;
	}

	public void setDesignExpProcessor(DesignExportProcessor designExpProcessor) {
		this.designExpProcessor = designExpProcessor;
	}

	public void setDesignRfcProcessor(DesignRfcProcessor designRfcProcessor) {
		this.designRfcProcessor = designRfcProcessor;
	}

	public void setCatalogProcessor(CatalogProcessor catalogProcessor) {
		this.catalogProcessor = catalogProcessor;
	}

	public void setPackRefreshProcessor(PackRefreshProcessor packRefreshProcessor) {
		this.packRefreshProcessor = packRefreshProcessor;
	}

	public void setPackUpdateProcessor(PackUpdateProcessor packUpdateProcessor) {
		this.packUpdateProcessor = packUpdateProcessor;
	}

	@Override
	public long generatePlatform(CmsRfcCI platRfc, long assemblyId,
			String userId, String scope) {
		CmsRfcCI designPlatformRfc = designRfcProcessor.generatePlatFromTmpl(platRfc, assemblyId, userId, scope); 
		return designPlatformRfc.getCiId();
	}

	@Override
	public long clonePlatform(CmsRfcCI platRfc, Long targetAssemblyId,
			long sourcePlatId, String userId, String scope) {
		return designRfcProcessor.clonePlatform(platRfc, targetAssemblyId, sourcePlatId, userId, scope);
	}

	@Override
	public long cloneAssembly(CmsCI assemblyCI, 
			long sourceAssemblyId, String userId, String scope) {
		return designRfcProcessor.cloneAssembly(assemblyCI, sourceAssemblyId, userId, scope);
	}

	@Override
	public long saveAssemblyAsCatalog(CmsCI catalogCI, 
			long sourceAssemblyId, String userId, String scope) {
		return catalogProcessor.saveAssemblyAsCatalog(catalogCI, sourceAssemblyId, userId, scope);
	}

	@Override
	public CatalogExport exportCatalog(long catalogCIid, String scope) {
		return catalogProcessor.exportCatalog(catalogCIid, scope);
	}

	@Override
	public long importCatalog(CatalogExport catExp, String userId,
			String scope) {
		return catalogProcessor.importCatalog(catExp, userId, scope);
	}

	@Override
	public long deletePlatform(long platformId, String userId, String scope) {
		return designRfcProcessor.deletePlatform(platformId, userId, scope);
	}

	@Override
	public DesignExportSimple exportDesign(long assemblyId, Long[] platformIds, String scope) {
		return designExpProcessor.exportDesign(assemblyId, platformIds, scope);
	}

	@Override
	public long lockUserChangedAttributes(long assemblyId, String scope, String userId, boolean dryRun) {
		return designExpProcessor.lockUserChangedAttributes(assemblyId, scope, userId, dryRun);
	}

	@Override
	public long importEnvironment(long assemblyId, String userId, String scope, EnvironmentExportSimple ees) {
		return environmentExpProcessor.importEnvironment(assemblyId, userId, scope, ees);
	}

	@Override
	public long importDesign(long assemblyId, String userId, String scope, DesignExportSimple des) {
		return designExpProcessor.importDesign(assemblyId, userId, scope, des);
	}

	@Override
	public void updateOwner(long assemblyId) {
		designExpProcessor.populateOwnerAttribute(assemblyId);
	}

	@Override
	public long refreshPack(long platformId, String packVersion, String userId, String scope) {
		return packRefreshProcessor.refreshPack(platformId, packVersion, userId, scope);
	}

	@Override
	public long updateFromPack(long platformId, String packVersion, String userId, String scope) {
		return packUpdateProcessor.updateFromPack(platformId, packVersion, userId, scope);
	}

	@Override
	public Map<String, List<?>> getPlatformRfcs(long platId, String userId, String scope) {
		return designRfcProcessor.getPlatformRfcs(platId, scope);
	}


	@Override
	public long discardReleaseForPlatform(long platId, String user) {
		return designRfcProcessor.discardReleaseForPlatform(platId, user);
	}

	@Override
	public long commitReleaseForPlatform(long platId, String desc, String userId) {
		return designRfcProcessor.commitReleaseForPlatform(platId, desc, userId);	}

	@Override
	public EnvironmentExportSimple exportEnvironment(long envId, Long[] platformIds, String scope) {
		return environmentExpProcessor.exportEnvironment(envId, platformIds, scope);
	}

	@Override
	public CmsRfcRelationSimple createComponent(long platId, CmsRfcRelationSimple relSimple, String userId, String scope) {
		return designRfcProcessor.createComponent(platId, relSimple, userId, scope);
	}
}
