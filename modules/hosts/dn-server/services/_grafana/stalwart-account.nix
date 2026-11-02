# One-account view of dn-cc's Stalwart: type an address into `account` and see
# every error the server recorded against it, in either direction.
#
# "Either direction" is the whole point of this dashboard: a bounce for
# alice@example.org is a `delivery.*` event whose `to` is alice, while a
# refusal of mail *from* her is an `smtp.*` event whose `from` is alice. Both
# sides of the envelope are structured metadata on the Loki stream, so the same
# text box covers both, and the From/To columns say which one matched.
#
# Reality check baked into the panel titles:
#   - `account` defaults to empty, and `.*` matches everything, so an empty box
#     shows the whole server. Type first, read second.
#   - Stalwart keeps the envelope sender in `from` and the envelope recipients
#     in `to` (comma-joined when a message has several). Header From/To (which
#     can differ, e.g. a mailing list) only exists on the `mail.received` rows
#     from the MTA hook, as `headerFrom`/`headerTo`.
#   - Delivery failures only appear for events in the tracer include list on
#     dn-cc (`services/stalwart.nix`); if a panel stays empty for an obviously
#     failing address, check that event is in that list.
# Nothing here changes server behaviour: no panel writes anything.
{
  lokiUid,
  promUid ? null,
}:
let
  ds = {
    type = "loki";
    uid = lokiUid;
  };

  sel = ''{service_name="stalwart"}'';

  # One filter *stage* (its own `|`) so the `or` here never swallows the
  # filters next to it -- in LogQL each `|` starts a separate stage, while
  # `and`/`or` inside one stage bind to that stage only.
  acct = ''| (from=~"(?i).*$account.*" or to=~"(?i).*$account.*")'';

  # `[.]` instead of `\.`: LogQL string literals reject the `\.` escape.
  #
  # dn-cc is the only peer allowed to relay for dn-server (`MtaStageRcpt` in
  # hosts/dn-cc/services/stalwart.nix), so every message a local user sends
  # arrives here from the WireGuard address and is re-checked as if it came
  # from a stranger. Those checks sit at their `disable` default -- nothing is
  # refused -- but the tracer records the verdict anyway, and a single backend
  # hop emits spf/iprev/dkim/dmarc failures that would drown a user's real
  # errors. Hence the hop is excluded from *these* verdicts only: a genuine
  # refusal on that hop (relay-not-allowed, undeliverable recipient) still
  # shows up, which is exactly how the relay bug was found.
  hopIp = "10.20.0.2";
  authFailF = ''(event=~"smtp[.](spf-ehlo|spf-from|dkim|dmarc|iprev|arc)-fail" and remoteIp!="${hopIp}")'';
  # Everything an inbound session is refused for before a message is queued.
  probeF = ''event=~"smtp[.](invalid-ehlo|did-not-say-ehlo|ehlo-expected|mailbox-does-not-exist|relay-not-allowed|mail-from-unauthenticated|rate-limit-exceeded|message-too-large|rcpt-to-duplicate|rcpt-to-missing|too-many-recipients|too-many-invalid-rcpt)"'';
  # Only the *verdict* half of spam.classify; the classifier half carries a
  # per-recipient confidence array instead of a verdict word.
  verdictF = ''event="spam.classify" and result=~"reject|discard"'';
  greylistF = ''event="smtp.rcpt-to-greylisted"'';
  banF = ''event=~"security[.].*"'';
  # Outbound side: every way a queued message fails to reach its recipient.
  delivF = ''event=~"delivery[.](failed|dsn-temp-fail|dsn-perm-fail|rcpt-to-failed|rcpt-to-rejected|mx-lookup-failed|null-mx|connect-error|greeting-failed|ehlo-rejected|double-bounce)"'';
  quotaF = ''event="queue.quota-exceeded"'';
  acceptedF = ''event=~"queue[.](authenticated-)?message-queued"'';

  # Everything that is an error from the account's point of view: refused,
  # bounced, or over quota. `security.*` is deliberately NOT here: those events
  # carry only `remoteIp`/`listenerId`, no envelope at all, so an account filter
  # can never match them -- bans are IP-scoped, see the spam dashboard.
  # The backend hop is filtered inside authFailF (see `hopIp` above), not here,
  # so that a genuine refusal on that hop still counts.
  errF = "(${authFailF} or ${probeF} or ${verdictF} or ${delivF} or ${quotaF})";

  # `security.*` events carry no envelope, so they are used nowhere below --
  # keeping the name here only documents that deliberate choice.
  rowFilter = "(${probeF} or ${authFailF})";

  instant = refId: expr: {
    inherit refId expr;
    datasource = ds;
    queryType = "instant";
  };
  logs = refId: expr: {
    inherit refId expr;
    datasource = ds;
    queryType = "range";
    maxLines = 1000;
  };

  statPanel =
    {
      id,
      title,
      color,
      x,
      w,
      filter,
    }:
    {
      inherit id title;
      type = "stat";
      datasource = ds;
      targets = [ (instant "A" "sum(count_over_time(${sel} | ${filter} ${acct} [$__range]))") ];
      gridPos = {
        inherit x w;
        y = 0;
        h = 4;
      };
      fieldConfig.defaults = {
        noValue = "0";
        color = {
          mode = "fixed";
          fixedColor = color;
        };
      };
      options = {
        colorMode = "background";
        graphMode = "none";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
    };

  timeseries =
    {
      id,
      title,
      gridPos,
      expr,
      legend,
    }:
    {
      inherit id title gridPos;
      type = "timeseries";
      datasource = ds;
      targets = [
        ((instant "A" expr) // { legendFormat = legend; })
      ];
      fieldConfig.defaults = {
        unit = "short";
        decimals = 0;
        min = 0;
        custom = {
          drawStyle = "line";
          lineWidth = 2;
          showPoints = "auto";
          pointSize = 4;
          stacking.mode = "normal";
          fillOpacity = 10;
          # An error class that fires once an hour must not leave gaps.
          spanNulls = true;
        };
      };
      options.legend = {
        displayMode = "list";
        placement = "bottom";
        showLegend = true;
      };
    };

  barGauge =
    {
      id,
      title,
      gridPos,
      expr,
      legend,
    }:
    {
      inherit id title gridPos;
      type = "bargauge";
      datasource = ds;
      targets = [
        ((instant "A" expr) // { legendFormat = legend; })
      ];
      options = {
        orientation = "horizontal";
        displayMode = "basic";
        showUnfilled = true;
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults.custom.filterable = true;
    };

  # A table whose rows are log lines: the metadata keys Stalwart ships as
  # structured metadata become the columns. `columns` also fixes the order;
  # a key that is absent on a given event simply leaves its cell empty.
  logTable =
    {
      id,
      title,
      gridPos,
      expr,
      columns,
      renames ? { },
      sortBy ? "Time",
    }:
    {
      inherit id title gridPos;
      type = "table";
      datasource = ds;
      targets = [ (logs "A" expr) ];
      transformations = [
        {
          id = "extractFields";
          options = {
            source = "labels";
            format = "json";
          };
        }
        {
          id = "filterFieldsByName";
          options.include.names = [ "Time" ] ++ columns;
        }
        {
          id = "organize";
          options = {
            indexByName = builtins.listToAttrs (
              builtins.genList (i: {
                name = builtins.elemAt ([ "Time" ] ++ columns) i;
                value = i;
              }) (builtins.length columns + 1)
            );
            renameByName = renames;
          };
        }
      ];
      fieldConfig = {
        defaults.custom = {
          filterable = true;
          cellOptions.type = "auto";
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Time";
            };
            properties = [
              {
                id = "custom.width";
                value = 170;
              }
            ];
          }
          {
            matcher = {
              id = "byName";
              options = "Event";
            };
            properties = [
              {
                id = "custom.width";
                value = 230;
              }
            ];
          }
        ];
      };
      options = {
        showHeader = true;
        cellHeight = "sm";
        sortBy = [
          {
            displayName = sortBy;
            desc = true;
          }
        ];
      };
    };
in
{
  uid = "stalwart-account";
  title = "Stalwart account";
  tags = [
    "stalwart"
    "mail"
    "account"
  ];
  timezone = "browser";
  refresh = "1m";
  schemaVersion = 39;
  time = {
    from = "now-7d";
    to = "now";
  };

  templating.list = [
    {
      name = "account";
      label = "Account (from or to)";
      type = "textbox";
      query = "";
      description = "Substring match against the envelope sender and recipients, case-insensitive. Empty = whole server.";
      current = {
        text = "";
        value = "";
      };
    }
  ];

  annotations.list = [
    {
      name = "Delivery failures";
      datasource = ds;
      enable = true;
      expr = "${sel} | ${delivF} ${acct}";
      titleFormat = "{{event}}";
      textFormat = "{{to}} {{details}} {{hostname}}";
      iconColor = "yellow";
      tagKeys = "";
    }
  ];

  panels = [
    # ---- Overview -------------------------------------------------------
    (statPanel {
      id = 1;
      title = "Errors";
      color = "red";
      x = 0;
      w = 6;
      filter = errF;
    })
    (statPanel {
      id = 2;
      title = "Refused (SMTP)";
      color = "orange";
      x = 6;
      w = 6;
      filter = "${probeF} or ${authFailF}";
    })
    (statPanel {
      id = 3;
      title = "Delivery failures";
      color = "yellow";
      x = 12;
      w = 6;
      filter = "${delivF} or ${quotaF}";
    })
    (statPanel {
      id = 4;
      title = "Accepted";
      color = "green";
      x = 18;
      w = 6;
      filter = acceptedF;
    })

    # ---- Errors over time -----------------------------------------------
    (timeseries {
      id = 5;
      title = "Errors over time, by event";
      gridPos = {
        x = 0;
        y = 4;
        w = 12;
        h = 9;
      };
      expr = "sum by (event) (count_over_time(${sel} | ${errF} ${acct} [$__interval]))";
      legend = "{{event}}";
    })
    (barGauge {
      id = 6;
      title = "What went wrong (whole range)";
      gridPos = {
        x = 12;
        y = 4;
        w = 12;
        h = 9;
      };
      expr = "sum by (event) (count_over_time(${sel} | ${errF} ${acct} [$__range]))";
      legend = "{{event}}";
    })

    # ---- The raw stream --------------------------------------------------
    {
      id = 7;
      title = "Everything the server recorded for this account";
      type = "logs";
      datasource = ds;
      gridPos = {
        x = 0;
        y = 13;
        w = 24;
        h = 11;
      };
      targets = [ (logs "A" "${sel} ${acct}") ];
      options = {
        showTime = true;
        wrapLogMessage = true;
        sortOrder = "Descending";
        enableLogDetails = true;
        dedupStrategy = "none";
      };
    }

    # ---- Inbound: why was it refused ------------------------------------
    (logTable {
      id = 8;
      title = "Inbound refusals & auth failures";
      gridPos = {
        x = 0;
        y = 24;
        w = 12;
        h = 10;
      };
      expr = "${sel} | ${rowFilter} ${acct}";
      columns = [
        "event"
        "result_eventName"
        "from"
        "to"
        "remoteIp"
        "listenerId"
      ];
      renames = {
        event = "Event";
        result_eventName = "Cause";
        from = "From";
        to = "To";
        remoteIp = "Remote IP";
        listenerId = "Listener";
      };
    })

    # ---- Outbound: why did it not arrive --------------------------------
    (logTable {
      id = 9;
      title = "Outbound delivery failures";
      gridPos = {
        x = 12;
        y = 24;
        w = 12;
        h = 10;
      };
      expr = "${sel} | (${delivF} or ${quotaF}) ${acct}";
      columns = [
        "event"
        "details"
        "code"
        "to"
        "from"
        "hostname"
        "queueId"
        "size"
      ];
      renames = {
        event = "Event";
        details = "Detail";
        code = "SMTP code";
        to = "Recipient";
        from = "Sender";
        hostname = "Remote host";
        queueId = "Queue ID";
        size = "Size";
      };
    })

    # ---- Messages, with the Subject the events never carry --------------
    (logTable {
      id = 10;
      title = "Messages (from the MTA hook: Subject + ids)";
      gridPos = {
        x = 0;
        y = 34;
        w = 24;
        h = 10;
      };
      expr = ''{service_name="stalwart", event="mail.received"} ${acct}'';
      columns = [
        "subject"
        "from"
        "to"
        "headerFrom"
        "size"
        "queueId"
        "remoteIp"
        "authenticatedAs"
      ];
      renames = {
        subject = "Subject";
        from = "Envelope from";
        to = "Envelope to";
        headerFrom = "Header From";
        size = "Size";
        queueId = "Queue ID";
        remoteIp = "Remote IP";
        authenticatedAs = "Authenticated as";
      };
    })

    # ---- Notes ------------------------------------------------------------
    {
      id = 11;
      title = "How to read this";
      type = "text";
      gridPos = {
        x = 0;
        y = 44;
        w = 24;
        h = 9;
      };
      options = {
        mode = "markdown";
        content = ''
          **Start here**

          Type part of an address into `Account (from or to)` above -- `alice`,
          `alice@example.org`, or a whole domain like `@example.org`. The box
          matches **both** sides of the envelope:

          * `to` = envelope recipients of an *inbound* message, and the
            recipient of an *outbound* delivery attempt.
          * `from` = envelope sender, i.e. the local account when it sends.

          Empty box = `.*` = the whole server, which is why the numbers look
          alarming before you type anything.

          **Which panel answers which question**

          * *Inbound refusals & auth failures* -- "why was mail to me
            rejected": `smtp.*-fail` (SPF/DKIM/DMARC/iprev/ARC),
            `smtp.relay-not-allowed`, `smtp.mailbox-does-not-exist`,
            `smtp.rate-limit-exceeded`, `smtp.message-too-large`,
            `smtp.rcpt-to-greylisted` (deferred, not refused).
          * *Outbound delivery failures* -- "why did my mail not arrive":
            `delivery.failed` (temporary, will retry), `delivery.dsn-temp-fail`
            / `delivery.dsn-perm-fail` (the bounce), `delivery.rcpt-to-failed`
            / `rcpt-to-rejected` (one recipient refused by the remote server),
            `mx-lookup-failed` / `null-mx` / `connect-error` /
            `greeting-failed` / `ehlo-rejected` (never reached SMTP),
            `delivery.double-bounce`, `queue.quota-exceeded`.
          * *Messages (MTA hook)* -- one row per received message with the
            `Subject` header, because Stalwart's telemetry events never carry
            it. Written by `services/stalwart-mta-hook.nix` on dn-cc.

          **Known gaps**

          * The two tables cannot be joined row-for-row: the hook answers
            before the verdict exists, and neither side carries the other's
            correlation id. Use To/From plus the timestamp to line them up.
          * Spam verdicts only appear if `SpamSettings.scoreReject` /
            `scoreDiscard` are above 0; they are still at the default `0`, so
            today mail is *tagged* as spam but never refused, and
            `spam.classify` only shows the classifier half.
          * Login failures (IMAP/JMAP/submission) are not attributable to an
            address on this stream: Stalwart's `auth.*` events carry the
            client IP, not an envelope, and `security.*` bans carry no envelope
            at all -- which is also why bans never show up here once you type
            an account. Use the *Stalwart spam* dashboard for those.
          * Transient delivery errors repeat per retry, so the counters count
            *events*, not messages.

          **Still missing = a tracer include list problem**

          Every event above has to be listed in the tracer `events` set in
          `modules/hosts/dn-cc/services/stalwart.nix`; anything not listed is
          simply never exported to Loki and no panel can show it.
        '';
      };
    }
  ];
}
