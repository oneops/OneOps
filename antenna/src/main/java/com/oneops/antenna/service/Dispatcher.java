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
package com.oneops.antenna.service;

import com.google.gson.Gson;
import com.oneops.antenna.domain.BasicSubscriber;
import com.oneops.antenna.domain.EmailSubscriber;
import com.oneops.notification.NotificationMessage;
import com.oneops.antenna.domain.SNSSubscriber;
import com.oneops.antenna.domain.SlackSubscriber;
import com.oneops.antenna.domain.URLSubscriber;
import com.oneops.antenna.domain.XMPPSubscriber;
import com.oneops.notification.filter.NotificationFilter;
import com.oneops.antenna.senders.NotificationSender;
import com.oneops.antenna.subscriptions.SubscriberService;
import com.oneops.cms.cm.domain.CmsCI;
import com.oneops.cms.cm.ops.domain.CmsOpsProcedure;
import com.oneops.cms.cm.ops.service.OpsProcedureProcessor;
import com.oneops.cms.cm.service.CmsCmProcessor;
import com.oneops.cms.dj.dal.DJDpmtMapper;
import com.oneops.cms.dj.domain.CmsDeployment;
import com.oneops.cms.dj.service.CmsDpmtProcessor;
import com.oneops.cms.md.service.CmsMdProcessor;
import com.oneops.cms.simple.domain.CmsCISimple;
import com.oneops.cms.util.CmsUtil;
import java.util.List;
import java.util.stream.Collectors;
import org.apache.commons.lang3.ArrayUtils;
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * The Class Dispatcher.
 */
public class Dispatcher {

    private static Logger logger = Logger.getLogger(Dispatcher.class);

    private final Gson gson;
    private final SubscriberService sbrService;
    private final NotificationSender eSender;
    private final NotificationSender snsSender;
    private final NotificationSender urlSender;
    private final NotificationSender xmppSender;
    private final NotificationSender slackSender;
    private final CmsCmProcessor cmProcessor;
    private final CmsDpmtProcessor dpmtProcessor;
    private final OpsProcedureProcessor procProcessor;
    private final CmsUtil cmsUtil;
    private DJDpmtMapper dpmtMapper;
    private CmsMdProcessor cmsMdProcessor;

    @Autowired
    public Dispatcher(Gson gson,
                      SubscriberService sbrService,
                      NotificationSender eSender,
                      NotificationSender snsSender,
                      NotificationSender urlSender,
                      NotificationSender xmppSender,
                      NotificationSender slackSender,
                      CmsCmProcessor cmProcessor,
                      CmsDpmtProcessor dpmtProcessor,
                      OpsProcedureProcessor procProcessor,
        DJDpmtMapper dpmtMapper,
        CmsMdProcessor mdProcessor,
        CmsUtil cmsUtil) {
        this.gson = gson;
        this.sbrService = sbrService;
        this.eSender = eSender;
        this.snsSender = snsSender;
        this.urlSender = urlSender;
        this.xmppSender = xmppSender;
        this.slackSender = slackSender;
        this.cmProcessor = cmProcessor;
        this.dpmtProcessor = dpmtProcessor;
        this.procProcessor = procProcessor;
        this.dpmtMapper =  dpmtMapper;
        this.cmsMdProcessor = mdProcessor;
        this.cmsUtil =cmsUtil;
    }

    /**
     * Message dispatcher logic.
     *
     * @param msg the msg
     */
    public void dispatch(NotificationMessage msg) {
        if (msg.getNsPath() == null) {
            String nsPath = getNsPath(msg);
            if (nsPath != null) {
                msg.setNsPath(nsPath);
            } else {
                logger.error("Can not figure out nsPath for msg " + gson.toJson(msg));
                return;
            }
        }

        List<BasicSubscriber> subscribers = sbrService.getSubscribersForNs(msg.getNsPath());
        try {
            for (BasicSubscriber sub : subscribers) {
                NotificationMessage nMsg = msg;

                if (sub.hasFilter() && !sub.getFilter().accept(nMsg)) {
                    continue;
                }
                if (sub.hasTransformer()) {
                    nMsg = sub.getTransformer().transform(nMsg);
                }
                if (sub instanceof EmailSubscriber) {
                    eSender.postMessage(nMsg, sub);
                } else if (sub instanceof SNSSubscriber) {
                    snsSender.postMessage(nMsg, sub);
                } else if (sub instanceof URLSubscriber) {
                  if (sub.getFilter() instanceof NotificationFilter) {
                    NotificationFilter nFilter = NotificationFilter.class.cast(sub.getFilter());
                    if (nFilter.isIncludeCi() && ArrayUtils.isNotEmpty(nFilter.getClassNames())) {
                      final List<Long> ciIds = dpmtMapper
                          .getDeploymentRfcCIs(msg.getCmsId(), null, null, nFilter.getClassNames(),
                              nFilter.getActions())
                          .stream()
                          .map(rfc -> rfc.getCiId())
                          .collect(Collectors.toList());
                      if(ciIds.isEmpty()){
                        // There are no ci's which sink is subscribed to , skip notifications.
                        continue;
                      }
                      final List<CmsCISimple> cis = cmProcessor.getCiByIdList(ciIds).stream()
                          .map(ci -> cmsUtil.custCI2CISimple(ci, "df")).collect(
                              Collectors.toList());
                      nMsg.setCis(cis);
                    }
                  }
                  if(logger.isDebugEnabled()){
                    logger.debug("nMsg " + gson.toJson(nMsg));
                  }
                  urlSender.postMessage(nMsg, sub);
                } else if (sub instanceof XMPPSubscriber) {
                    xmppSender.postMessage(nMsg, sub);
                } else if (sub instanceof SlackSubscriber) {
                    slackSender.postMessage(nMsg, sub);
                }
            }
        } catch (Exception e) {
            logger.error("Message dispatching failed.", e);
        }
    }

    /**
     * Get nspath based on the notification message type.
     *
     * @param msg notification message
     * @return nspath string
     */
    private String getNsPath(NotificationMessage msg) {
        String nsPath;
        switch (msg.getType()) {
            case ci:
                nsPath = getNsPathForCi(msg.getCmsId());
                break;
            case deployment:
                nsPath = getNsPathForDpmt(msg.getCmsId());
                break;
            case procedure:
                nsPath = getNsPathForProc(msg.getCmsId());
                break;
            default:
                nsPath = null;
                break;
        }
        return nsPath;
    }

    /**
     * Nspath for ci message type
     *
     * @param ciId ci id
     * @return nspath
     */
    private String getNsPathForCi(long ciId) {
        CmsCI ci = cmProcessor.getCiById(ciId);
        if (ci == null) {
            logger.error("Can not get ci with id - " + ciId);
            return null;
        }
        return ci.getNsPath();
    }

    /**
     * Nspath for deployment message type
     *
     * @param dpmtId deployment id
     * @return nspath
     */
    private String getNsPathForDpmt(long dpmtId) {
        CmsDeployment dpmt = dpmtProcessor.getDeployment(dpmtId);
        if (dpmt == null) {
            logger.error("Can not get deployment with id - " + dpmtId);
            return null;
        }
        return dpmt.getNsPath();
    }

    /**
     * Nspath for procedure action type
     *
     * @param procId proc id
     * @return nspath
     */
    private String getNsPathForProc(long procId) {
        CmsOpsProcedure proc = procProcessor.getCmsOpsProcedure(procId, false);
        if (proc == null) {
            logger.error("Can not get procedure with id - " + procId);
            return null;
        }
        return getNsPathForCi(proc.getCiId());
    }


    /**
     * Notification event dispatch methods.
     */
    public enum Method {

        /**
         * Dispatching methods
         */
        SYNC("sync"), ASYNC("async");

        /**
         * Dispatch method name
         */
        private String name;

        /**
         * Enum constructor
         *
         * @param name
         */
        Method(String name) {
            this.name = name;
        }

        /**
         * Returns the dispatch method name.
         *
         * @return name
         */
        String getName() {
            return name;
        }
    }
}

