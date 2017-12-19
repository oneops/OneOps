package com.oneops.transistor.service;

import com.oneops.cms.simple.domain.CmsCISimple;
import com.oneops.cms.simple.domain.CmsRfcCISimple;

/*******************************************************************************
 *
 *   Copyright 2016 Walmart, Inc.
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

public class CapacityData {
    private CmsRfcCISimple rfc;
    private String size; 
    private CmsCISimple cloud;


    public CmsRfcCISimple getRfc() {
        return rfc;
    }

    public CmsCISimple getCloud() {
        return cloud;
    }

    public String getSize() {
        return size;
    }

    CapacityData(CmsRfcCISimple rfc, CmsCISimple cloud) {
        this.rfc = rfc;
        this.cloud = cloud;
        this.size = rfc.getCiAttributes().get("size");
    }
}