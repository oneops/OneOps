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
package com.oneops.antenna.senders.generic;

import com.oneops.notification.NotificationMessage;
import com.oneops.notification.NotificationSeverity;
import com.oneops.notification.NotificationType;
import com.oneops.antenna.domain.XMPPSubscriber;
import org.testng.annotations.Test;

public class ServiceTest {

    @Test
    public void simpleLogTest() {
        LoggingMsgService service = new LoggingMsgService();
        XMPPSubscriber subscriber = new XMPPSubscriber();

        NotificationMessage msg = new NotificationMessage();
        msg.setNsPath("/a/b/c/d/e/f");
        msg.setSource("sourceOpen");
        msg.setSubject("subjectOfMsg");
        msg.setText("message-text-xya");
        msg.setType(NotificationType.deployment);
        msg.setSeverity(NotificationSeverity.critical);
        msg.setTemplateName("template12");
        msg.setTimestamp(System.currentTimeMillis());
        boolean res = service.postMessage(msg, subscriber);
        assert (res);
    }
}
