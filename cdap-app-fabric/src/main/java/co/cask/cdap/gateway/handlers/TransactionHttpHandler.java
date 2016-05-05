/*
 * Copyright © 2015 Cask Data, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package co.cask.cdap.gateway.handlers;

import co.cask.cdap.common.conf.Constants;
import co.cask.cdap.gateway.handlers.util.AbstractAppFabricHttpHandler;
import co.cask.http.BodyProducer;
import co.cask.http.HttpResponder;
import co.cask.tephra.InvalidTruncateTimeException;
import co.cask.tephra.TransactionCouldNotTakeSnapshotException;
import co.cask.tephra.TransactionSystemClient;
import com.google.common.base.Throwables;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableMultimap;
import com.google.gson.reflect.TypeToken;
import com.google.inject.Inject;
import org.jboss.netty.buffer.ChannelBuffer;
import org.jboss.netty.buffer.ChannelBuffers;
import org.jboss.netty.handler.codec.http.HttpRequest;
import org.jboss.netty.handler.codec.http.HttpResponseStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.util.Map;
import java.util.Set;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;

/**
 * Handler to for managing transaction states.
 */
@Path(Constants.Gateway.API_VERSION_3)
public class TransactionHttpHandler extends AbstractAppFabricHttpHandler {

  private static final Logger LOG = LoggerFactory.getLogger(TransactionHttpHandler.class);
  private static final Type STRING_LONG_MAP_TYPE = new TypeToken<Map<String, Long>>() { }.getType();
  private static final Type STRING_LONG_SET_MAP_TYPE = new TypeToken<Map<String, Set<Long>>>() { }.getType();

  private final TransactionSystemClient txClient;

  @Inject
  public TransactionHttpHandler(TransactionSystemClient txClient) {
    this.txClient = txClient;
  }

  /**
   * Retrieve the state of the transaction manager.
   */
  @Path("/transactions/state")
  @GET
  public void getTxManagerSnapshot(HttpRequest request, HttpResponder responder)
    throws TransactionCouldNotTakeSnapshotException, IOException {
    LOG.trace("Taking transaction manager snapshot at time {}", System.currentTimeMillis());
    LOG.trace("Took and retrieved transaction manager snapshot successfully.");
    responder.sendContent(HttpResponseStatus.OK, new BodyProducer() {
      // do this on first read, instead of here? what if it never gets closed like this?
      InputStream in = txClient.getSnapshotInputStream();

      @Override
      public ChannelBuffer nextChunk() throws Exception {
        // netty doesn't copy the readBytes buffer, so we have to reallocate a new buffer
        byte[] readBytes = new byte[4096];
        int res = in.read(readBytes, 0, 4096);
        if (res == -1) {
          return ChannelBuffers.EMPTY_BUFFER;
        }
        // If failed to send chunk, IOException will be raised.
        // It'll just propagated to the netty-http library to handle it
        return ChannelBuffers.wrappedBuffer(readBytes, 0, res);
      }

      @Override
      public void finished() throws Exception {
        in.close();
      }

      @Override
      public void handleError(Throwable throwable) {
        try {
          in.close();
        } catch (IOException e) {
          Throwables.propagate(e);
        }
      }
      // can be nullable, right...?
    }, ImmutableMultimap.<String, String>of());
  }

  /**
   * Invalidate a transaction.
   * @param txId transaction ID.
   */
  @Path("/transactions/{tx-id}/invalidate")
  @POST
  public void invalidateTx(HttpRequest request, HttpResponder responder,
                           @PathParam("tx-id") String txId) {
    try {
      long txIdLong = Long.parseLong(txId);
      boolean success = txClient.invalidate(txIdLong);
      if (success) {
        LOG.info("Transaction {} successfully invalidated", txId);
        responder.sendStatus(HttpResponseStatus.OK);
      } else {
        LOG.info("Transaction {} could not be invalidated: not in progress.", txId);
        responder.sendStatus(HttpResponseStatus.CONFLICT);
      }
    } catch (NumberFormatException e) {
      LOG.info("Could not invalidate transaction: {} is not a valid tx id", txId);
      responder.sendStatus(HttpResponseStatus.BAD_REQUEST);
    }
  }

  @Path("/transactions/invalid/remove/until")
  @POST
  public void truncateInvalidTxBefore(HttpRequest request,
                                      HttpResponder responder) throws InvalidTruncateTimeException {
    Map<String, Long> body;
    try {
      body = parseBody(request, STRING_LONG_MAP_TYPE);
    } catch (IllegalArgumentException e) {
      responder.sendString(HttpResponseStatus.BAD_REQUEST, "Invalid time value in request");
      return;
    }

    if (body == null || !body.containsKey("time")) {
      responder.sendString(HttpResponseStatus.BAD_REQUEST, "Time not specified");
      return;
    }

    long time = body.get("time");
    txClient.truncateInvalidTxBefore(time);
    responder.sendStatus(HttpResponseStatus.OK);
  }

  @Path("/transactions/invalid/remove/ids")
  @POST
  public void truncateInvalidTx(HttpRequest request, HttpResponder responder) {
    Map<String, Set<Long>> body;
    try {
      body = parseBody(request, STRING_LONG_SET_MAP_TYPE);
    } catch (IllegalArgumentException e) {
      responder.sendString(HttpResponseStatus.BAD_REQUEST, "Invalid ids specified in request");
      return;
    }

    if (body == null || !body.containsKey("ids")) {
      responder.sendString(HttpResponseStatus.BAD_REQUEST, "Transaction ids not specified");
      return;
    }

    Set<Long> txIds = body.get("ids");
    txClient.truncateInvalidTx(txIds);
    responder.sendStatus(HttpResponseStatus.OK);
  }

  @Path("/transactions/invalid/size")
  @GET
  public void invalidTxSize(HttpRequest request, HttpResponder responder) {
    int invalidSize = txClient.getInvalidSize();
    responder.sendJson(HttpResponseStatus.OK, ImmutableMap.of("size", invalidSize));
  }

  /**
   * Reset the state of the transaction manager.
   */
  @Path("/transactions/state")
  @POST
  public void resetTxManagerState(HttpRequest request, HttpResponder responder) {
    txClient.resetState();
    responder.sendStatus(HttpResponseStatus.OK);
  }
}
