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
package com.oneops.inductor;

import static java.lang.String.format;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import com.oneops.cms.util.CmsConstants;

import org.apache.log4j.Logger;
import org.zeroturnaround.exec.ProcessExecutor;
import org.zeroturnaround.exec.stream.LogOutputStream;

public class ProcessRunner {

  private static final Logger logger = Logger.getLogger(ProcessRunner.class);

  private static final List<String> LOCAL_CMDS = Arrays.asList("chef-solo", "kitchen");

  private int timeoutInSeconds = 7200; // 2hr

  private Config config;

  ProcessRunner(Config config) {
    this.config = config;
  }

  public int getTimeoutInSeconds() {
    return timeoutInSeconds;
  }

  public void setTimeoutInSeconds(int timeoutInSeconds) {
    this.timeoutInSeconds = timeoutInSeconds;
  }

  /**
   * Process retry over loaded method with shutdown cloud processing.
   *
   * @param executionContext@return process result
   */
  public ProcessResult executeProcessRetry(ExecutionContext executionContext) {
    boolean shutdown = config.hasCloudShutdownFor(executionContext.getWo());
    int maxRetries = executionContext.getRetryCount();
    if (shutdown) {
      // If the cloud is already shutdown, set max retry count to 0.
      // This is to avoid unnecessary command retries for already
      // decommissioned/deleted cloud resources.
      maxRetries = 0;
      // Reduce the rsync timeout (default is 10).
      long timeout = config.getCmdTimeout();
      for (int i = 0; i < executionContext.getCmd().length; i++) {
        if (executionContext.getCmd()[i].startsWith("--timeout=")) {
          executionContext.getCmd()[i] = "--timeout=" + timeout;
        }
      }
    }
    ProcessResult result = executeProcessRetry(executionContext.getCmd(), executionContext.getLogKey(), maxRetries,
        InductorConstants.PRIVATE_IP);
    // Mark the process execution result code to 0 for the shutdown.clouds.
    if (shutdown) {
      logger.warn(executionContext.getLogKey()
          + " ### Set the result code to 0 as the cloud resource for this component is already released.");
      result.setResultCode(0);
    }
    return result;
  }

  /**
   * Wrapper for process retry
   *
   * @param cmd         command to execute
   * @param logKey      log key
   * @param max_retries max retry count
   * @return process result.
   */
  public ProcessResult executeProcessRetry(String[] cmd, String logKey, int max_retries) {
    return executeProcessRetry(cmd, logKey, max_retries, InductorConstants.PRIVATE_IP);
  }

  public ProcessResult executeProcessRetry(String[] cmd, String logKey) {
    return executeProcessRetry(cmd, logKey, config.getRetryCount(), config.getIpAttribute());
  }

  /**
   * Execute the command and retry if it fails.
   *
   * @param cmd          command to execute
   * @param logKey       log key
   * @param max_retries  max retry count
   * @param ip_attribute ip address
   * @return process result
   */
  public ProcessResult executeProcessRetry(String[] cmd, String logKey, int max_retries, String ip_attribute) {

    int count = 0;
    ProcessResult result = new ProcessResult();

    while ((result.getResultCode() != 0 && count < max_retries + 1) || result.isRebooting()) {
      if (count > 0) {
        logger.warn(logKey + "retry #: " + count);
        if (result.getResultMap().containsKey(InductorConstants.SHARED_IP)
            && ip_attribute.equalsIgnoreCase(InductorConstants.PUBLIC_IP)) {

          String ip = result.getResultMap().get(InductorConstants.SHARED_IP);
          String oldUserHost = cmd[1];
          logger.info("retrying using shared_ip: " + ip);
          String newUserHost = oldUserHost.replaceFirst("@.*", "@" + ip);
          cmd[1] = newUserHost;
        }
      }
      result.setRebooting(false);

      long startTime = System.currentTimeMillis();
      executeProcess(cmd, logKey, result, null, null);
      long endTime = System.currentTimeMillis();
      long duration = endTime - startTime;
      logger.info(logKey + "cmd took: " + duration + " ms");

      if (result.isRebooting()) {
        logger.info(logKey + " rebooting flag is set");
        return result;
      }

      count++;
      try {
        if (result.getResultCode() != 0 && count - 1 < max_retries) {
          // retry quick (1 sec) then decay
          long sleepSec = count * 7 - 6;
          logger.info("sleeping " + sleepSec + " sec...");
          Thread.sleep(sleepSec * 1000L);
        }
      } catch (InterruptedException ie) {
        ie.printStackTrace();
      }
    }

    // adding count to retry
    result.getTagMap().put(CmsConstants.INDUCTOR_RETRIES, Integer.toString(count - 1));
    logger.info(logKey + " ### EXEC EXIT CODE: " + result.getResultCode());
    return result;
  }

  /**
   * Creates a process and logs the output
   */
  public void executeProcess(String[] cmd, String logKey, ProcessResult result, Map<String, String> additionalEnvVars,
      File workingDir) {

    Map<String, String> env = getEnvVars(cmd, additionalEnvVars);
    logger.info(format("%s Cmd: %s, Additional Env Vars: %s", logKey, String.join(" ", cmd), additionalEnvVars));
    try {
      setTimeoutInSeconds((int) config.getChefTimeout());
      OutputHandler outputStream = new OutputHandler(logger, logKey, result);
      ErrorHandler errorStream = new ErrorHandler(logger, logKey, result);
      if (env == null) {
        env = new HashMap<>();
      }
      result.setResultCode(new ProcessExecutor().command(cmd).environment(env).directory(workingDir)
          .redirectOutput(new LogOutputStream() {
            @Override
            protected void processLine(String line) {
              for (String l : line.split("\n")) {
                outputStream.writeOutputToLogger(l);
              }
            }
          }).redirectError(new LogOutputStream() {
            @Override
            protected void processLine(String line) {
              for (String l : line.split("\n")) {
                errorStream.writeOutputToLogger(l);
              }
            }
          }).timeout(timeoutInSeconds, TimeUnit.SECONDS).execute().getExitValue());

      // set fault to last error if fault map is empty
      if (result.getResultCode() != 0 && result.getFaultMap().keySet().size() < 1) {
        result.getFaultMap().put("ERROR", result.getLastError());
      }
    } catch (TimeoutException e) {
      logger.error(logKey + e);
      result.setResultCode(-1);
    } catch (InterruptedException e) {
      logger.error(logKey + e);
      result.setResultCode(-2);
    } catch (IOException e) {
      logger.error(logKey + e);
      result.setResultCode(1);
    }
  }

  /**
   * Returns env variables to be used for local commands, else returns null.
   *
   * @param cmd       command array
   * @param extraVars additional env vars for local command.
   * @return env vars map or <code>null</code>. command.
   */
  public Map<String, String> getEnvVars(String[] cmd, Map<String, String> extraVars) {
    if (LOCAL_CMDS.contains(cmd[0].toLowerCase())) {
      Map<String, String> envVars = new HashMap<>();
      envVars.putAll(System.getenv());
      envVars.putAll(config.getEnvVars());
      if (extraVars != null) {
        envVars.putAll(extraVars);
      }
      return envVars;
    }
    return null;
  }
}