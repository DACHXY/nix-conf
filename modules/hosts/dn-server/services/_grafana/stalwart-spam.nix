# Spam / abuse view of dn-cc's Stalwart, built from the events that
# dn-cc/services/alloy.nix ships to Loki, plus the handful of Prometheus
# counters that actually exist today.
#
# Reality check baked into the panel titles and the closing notes panel:
#   - Stalwart only exports a Prometheus counter once it has fired at least
#     once (value > 0), so `spam.classify`, `spam.train-*`, `smtp.dkim-fail`
#     and friends have no series at all until that code path runs.
#   - `queue.count` is an enterprise-only gauge and `*-connection-end` is a
#     span end (never counted), so neither can be charted here.
#   - `spam.classify` fire either from the classifier (Result = per-recipient
#     confidence) or from the verdict path (Result = "reject"/"discard").
# Nothing here changes server behaviour: no dashboard panel writes anything.
{ lokiUid, promUid }:
let
  ds = {
    type = "loki";
    uid = lokiUid;
  };
  pds = {
    type = "prometheus";
    uid = promUid;
  };

  sel = ''{service_name="stalwart"}'';

  # Messages that made it into the queue (= accepted by the SMTP layer).
  queuedFilter = ''event=~"queue.(authenticated-)?message-queued"'';
  # Only the *verdict* half of spam.classify; the classifier half carries the
  # per-recipient confidence array instead of a verdict word.
  verdictFilter = ''event="spam.classify" and result=~"reject|discard"'';
  # Deferred by greylisting: neither accepted nor refused yet.
  greylistFilter = ''event="smtp.rcpt-to-greylisted"'';
  authFailFilter = ''event=~"smtp.(spf-ehlo|spf-from|dkim|dmarc|iprev|arc)-fail"'';
  authPassFilter = ''event=~"smtp.(spf-ehlo|spf-from|dmarc|iprev|arc)-pass" or event="smtp.spf-from-pass"'';
  # Scanner / relay-abuse signatures: everything an inbound session is refused
  # for before (or instead of) a message ever being accepted.
  probeFilter = ''event=~"smtp.(invalid-ehlo|did-not-say-ehlo|auth-mechanism-not-supported|mailbox-does-not-exist|relay-not-allowed|mail-from-unauthenticated|rate-limit-exceeded|rcpt-to-duplicate|rcpt-to-missing|message-too-large)"'';
  # `[.]` instead of `\.`: LogQL string literals reject the `\.` escape.
  banFilter = ''event=~"security[.].*"'';
  searchArm = ''(remoteIp=~".*$search.*" or from=~"(?i).*$search.*" or to=~"(?i).*$search.*")'';

  # Every outcome an inbound message can have, so the table shows accepted and
  # greylisted mail too, not just the refusals.
  messageFilter = "(${verdictFilter}) or (${probeFilter}) or (${queuedFilter}) or (${greylistFilter})";

  # 0 accepted, 1 greylisted, 2 refused by SMTP, 3 refused by the spam verdict.
  # Emitted as a number, not as the display word: a session can hold several
  # events (e.g. accept + reject), and the groupBy step then has to pick *one*
  # value per session. max() over a rank picks the most severe one, and the
  # value mapping turns the rank back into the coloured word in the table.
  # Templates here have no sprig helpers, only plain comparisons.
  actionRank = ''{{ if or (eq .result "reject") (eq .result "discard") }}3{{ else if eq .event "smtp.rcpt-to-greylisted" }}1{{ else if eq .event "queue.message-queued" }}0{{ else if eq .event "queue.authenticated-message-queued" }}0{{ else }}2{{ end }}'';

  # Same classification as `actionRank`, as the word the table shows. Kept as a
  # string so the value mapping below can match it exactly.
  actionWord = ''{{ if or (eq .result "reject") (eq .result "discard") }}reject (spam){{ else if eq .event "smtp.rcpt-to-greylisted" }}greylist{{ else if eq .event "queue.message-queued" }}accept{{ else if eq .event "queue.authenticated-message-queued" }}accept{{ else }}reject (SMTP){{ end }}'';

  instant = refId: expr: {
    inherit refId expr;
    datasource = ds;
    queryType = "instant";
  };
  promInstant = refId: expr: {
    inherit refId expr;
    datasource = pds;
    queryType = "instant";
  };
  promRange = refId: expr: legendFormat: {
    inherit refId expr legendFormat;
    datasource = pds;
    queryType = "range";
  };
  rate = refId: filter: legendFormat: {
    refId = refId;
    # count_over_time, not rate(): the y-axis then reads as whole events per
    # interval instead of events-per-second fractions.
    expr = "sum(count_over_time(${sel} | ${filter} [$__interval]))";
    inherit legendFormat;
    datasource = ds;
    queryType = "range";
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
      datasource,
      targets,
      w ? 4,
    }:
    {
      inherit
        id
        title
        datasource
        targets
        ;
      type = "stat";
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

  # `noValue = "0"` for a Loki counter: an empty result is genuinely zero here.
  # `filter` is a label filter; the stream selector is added here so callers
  # cannot forget it.
  lokiStat =
    id: title: color: x: w: filter:
    statPanel {
      inherit
        id
        title
        color
        x
        w
        ;
      datasource = ds;
      targets = [ (instant "A" "sum(count_over_time(${sel} | ${filter} [$__range]))") ];
    };

  # For stats whose query is not a plain count (e.g. "how many distinct IPs").
  lokiExprStat =
    id: title: color: x: w: expr:
    statPanel {
      inherit
        id
        title
        color
        x
        w
        ;
      datasource = ds;
      targets = [ (instant "A" expr) ];
    };

  # Prometheus counters that may not exist yet fall back to 0 with
  # `or vector(0)` instead of showing "No data".
  promStat =
    id: title: color: x: w: expr:
    statPanel {
      inherit
        id
        title
        color
        x
        w
        ;
      datasource = pds;
      targets = [ (promInstant "A" "sum(increase(${expr}{machine=~\"$machine\"}[$__range])) or vector(0)") ];
    };

  timeseries =
    {
      id,
      title,
      gridPos,
      targets,
      stacking ? "normal",
      datasource ? ds,
    }:
    {
      inherit
        id
        title
        gridPos
        targets
        datasource
        ;
      type = "timeseries";
      fieldConfig.defaults = {
        unit = "short";
        decimals = 0;
        min = 0;
        custom = {
          drawStyle = "line";
          lineWidth = 2;
          showPoints = "auto";
          pointSize = 4;
          stacking.mode = stacking;
          fillOpacity = 10;
          # Sparse series (an event happens in one interval, then nothing for
          # hours) must not leave visible gaps.
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
      fieldConfig.defaults.custom = {
        filterable = true;
      };
    };

  logTable =
    {
      id,
      title,
      gridPos,
      expr,
      columns,
      renames,
      overrides ? [ ],
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
        inherit overrides;
      };
      options = {
        showHeader = true;
        cellHeight = "sm";
        sortBy = [
          {
            displayName = "Time";
            desc = true;
          }
        ];
      };
    };

  # Word -> colour mapping for the Action column. The keys are the exact
  # strings `actionWord` emits: Grafana 13 only matches value mappings against
  # string values, so the field must stay a string (see the note at
  # `actionRank`).
  statusColor = {
    type = "value";
    options = {
      accept = {
        text = "accept";
        index = 0;
        color = "green";
      };
      greylist = {
        text = "greylist";
        index = 1;
        color = "blue";
      };
      "reject (SMTP)" = {
        text = "reject (SMTP)";
        index = 2;
        color = "orange";
      };
      "reject (spam)" = {
        text = "reject (spam)";
        index = 3;
        color = "red";
      };
    };
  };
in
{
  uid = "stalwart-spam";
  title = "Stalwart spam";
  tags = [
    "stalwart"
    "spam"
    "mail"
  ];
  timezone = "browser";
  refresh = "1m";
  schemaVersion = 39;
  time = {
    from = "now-24h";
    to = "now";
  };

  templating.list = [
    {
      name = "search";
      label = "Search (IP / from / to)";
      type = "textbox";
      query = "";
      current = {
        text = "";
        value = "";
      };
    }
    {
      # Both Stalwart hosts are scraped under the same job, so this is the
      # switch between "one combined number" (All) and "just dn-cc" or
      # "just dn-server". Only the Prometheus panels use it.
      name = "machine";
      label = "Machine (Prometheus)";
      type = "query";
      datasource = pds;
      definition = ''label_values(up{job="stalwart"}, machine)'';
      query = {
        query = ''label_values(up{job="stalwart"}, machine)'';
        refId = "StandardVariableQuery";
      };
      refresh = 1;
      includeAll = true;
      multi = true;
      allValue = ".*";
      current = {
        selected = true;
        text = [ "All" ];
        value = [ "$__all" ];
      };
    }
  ];

  panels = [
    # ---- Overview -------------------------------------------------------
    (lokiStat 1 "Queued" "green" 0 4 queuedFilter)
    (lokiStat 2 "Spam verdicts" "red" 4 4 verdictFilter)
    (lokiStat 3 "Auth failures" "orange" 8 4 authFailFilter)
    (lokiStat 4 "Bans issued" "purple" 12 4 banFilter)
    (lokiExprStat 5 "Offending IPs" "blue" 16 4
      "count(count by (remoteIp) (count_over_time(${sel} | ${probeFilter} [$__range])))"
    )
    (promStat 6 "DNSBL errors (metric)" "yellow" 20 4 "spam_dnsbl_error")

    # ---- Traffic & threat mix -------------------------------------------
    (timeseries {
      id = 7;
      title = "Traffic & threat mix";
      gridPos = {
        x = 0;
        y = 12;
        w = 12;
        h = 8;
      };
      stacking = "normal";
      targets = [
        (rate "A" queuedFilter "Queued")
        (rate "B" probeFilter "Rejected by SMTP")
        (rate "C" verdictFilter "Spam verdict")
        (rate "D" banFilter "Ban")
      ];
    })
    (timeseries {
      id = 8;
      title = "Scanner probes vs accepted";
      gridPos = {
        x = 12;
        y = 12;
        w = 12;
        h = 8;
      };
      stacking = "none";
      targets = [
        (rate "A" probeFilter "Scanner probe")
        (rate "B" queuedFilter "Accepted")
      ];
    })

    # ---- Sender authentication ------------------------------------------
    (timeseries {
      id = 9;
      title = "Sender auth pass vs fail (SPF / DKIM / DMARC / IPREV / ARC)";
      gridPos = {
        x = 12;
        y = 4;
        w = 12;
        h = 8;
      };
      stacking = "none";
      targets = [
        (rate "A" authPassFilter "pass")
        # One line per mechanism: the fail events are split out instead of being
        # summed into a single "fail" series, so a DMARC drop is not hidden
        # behind a burst of SPF-HELO noise.
        {
          refId = "B";
          expr = ''sum by (mech) (count_over_time(${sel} | ${authFailFilter} | label_format mech=`{{ regexReplaceAll "^(smtp[.])|(-fail)$" .event "" }}` [$__interval]))'';
          legendFormat = "{{mech}} fail";
          datasource = ds;
          queryType = "range";
        }
      ];
    })
    {
      id = 13;
      title = "Failed-auth senders";
      type = "table";
      datasource = ds;
      gridPos = {
        x = 0;
        y = 20;
        w = 24;
        h = 10;
      };
      targets = [
        (
          (instant "A" "sum by (remoteIp, from) (count_over_time(${sel} | ${authFailFilter} | ${searchArm} [$__range]))")
          // {
            legendFormat = "";
          }
        )
      ];
      transformations = [
        {
          id = "organize";
          options.renameByName = {
            remoteIp = "IP";
            from = "From";
            Value = "Failures";
          };
        }
        {
          id = "sortBy";
          options.sort = [
            {
              field = "Failures";
              desc = true;
            }
          ];
        }
        {
          id = "limit";
          options.limitField = 20;
        }
      ];
      fieldConfig.defaults.custom = {
        filterable = true;
        cellOptions.type = "auto";
      };
      options = {
        showHeader = true;
        cellHeight = "sm";
      };
    }
    (logTable {
      id = 14;
      title = "Recent bans";
      gridPos = {
        x = 0;
        y = 52;
        w = 24;
        h = 10;
      };
      expr = "${sel} | ${banFilter} | ${searchArm}";
      columns = [
        "remoteIp"
        "event"
        "reason"
        "listenerId"
        "trace_id"
      ];
      renames = {
        remoteIp = "IP";
        event = "Reason";
        reason = "Detail";
        listenerId = "Listener";
        trace_id = "Session";
      };
      overrides = [
        {
          matcher = {
            id = "byName";
            options = "Reason";
          };
          properties = [
            {
              id = "custom.cellOptions";
              value.type = "color-text";
            }
            {
              id = "mappings";
              value = [
                {
                  type = "value";
                  options = {
                    "security.authentication-ban" = {
                      index = 0;
                      text = "authentication-ban";
                      color = "red";
                    };
                    "security.abuse-ban" = {
                      index = 1;
                      text = "abuse-ban";
                      color = "orange";
                    };
                    "security.scan-ban" = {
                      index = 2;
                      text = "scan-ban";
                      color = "purple";
                    };
                    "security.ip-blocked" = {
                      index = 3;
                      text = "ip-blocked";
                      color = "dark-red";
                    };
                  };
                }
              ];
            }
          ];
        }
      ];
    })

    # ---- Messages (subject view) ------------------------------------------
    # One row per message, straight from the DATA-stage MTA hook on dn-cc
    # (services/stalwart-mta-hook.nix). Stalwart's own telemetry never carries
    # the Subject header, and the hook is the only place it leaves the server,
    # so this table — not the event table below — is the per-message view.
    {
      id = 21;
      title = "Messages — one row per mail (subject from the MTA hook)";
      type = "table";
      datasource = ds;
      gridPos = {
        x = 0;
        y = 30;
        w = 24;
        h = 10;
      };
      targets = [
        (logs "A" ''${sel} | event="mail.received" | label_format remoteIp=`{{ .remoteIp }}`, sender=`{{ .from }}`, recipient=`{{ .to }}`, subject=`{{ .subject }}`, msgSize=`{{ .size }}`, queueId=`{{ .queueId }}`, authenticatedAs=`{{ .authenticatedAs }}`, listener=`{{ .listenerId }}` | (remoteIp=~".*$search.*" or sender=~"(?i).*$search.*" or recipient=~"(?i).*$search.*" or subject=~"(?i).*$search.*")'')
      ];
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
          options.include.names = [
            "Time"
            "remoteIp"
            "sender"
            "recipient"
            "subject"
            "msgSize"
            "queueId"
            "authenticatedAs"
            "listener"
          ];
        }
        {
          id = "convertFieldType";
          options.conversions = [
            {
              targetField = "msgSize";
              destinationType = "number";
            }
          ];
        }
        {
          id = "organize";
          options = {
            excludeByName = { };
            renameByName = {
              Time = "Time";
              remoteIp = "IP address";
              sender = "From";
              recipient = "To";
              subject = "Subject";
              msgSize = "Size";
              authenticatedAs = "Auth user";
              queueId = "Queue ID";
              listener = "Listener";
            };
            indexByName = {
              Time = 0;
              remoteIp = 1;
              sender = 2;
              recipient = 3;
              subject = 4;
              msgSize = 5;
              authenticatedAs = 6;
              queueId = 7;
              listener = 8;
            };
          };
        }
      ];
      fieldConfig.defaults.custom = {
        filterable = true;
        cellOptions.type = "auto";
      };
      options = {
        showHeader = true;
        cellHeight = "sm";
        sortBy = [
          {
            displayName = "Time";
            desc = true;
          }
        ];
      };
    }

    # ---- Spam verdicts ---------------------------------------------------
    {
      id = 15;
      title = "Message events — one row per session (accept / greylist / reject, Subject from the MTA hook)";
      type = "table";
      datasource = ds;
      gridPos = {
        x = 0;
        y = 40;
        w = 24;
        h = 12;
      };
      targets = [
        (logs "A" ''${sel} | ${messageFilter} | label_format from=`{{ .from }}`, to=`{{ regexReplaceAll "[^a-zA-Z0-9@._+=,-]" .to "" }}`, remoteIp=`{{ .remoteIp }}`, queueId=`{{ .queueId }}`, reason=`{{ .reason }}`, score=`{{ regexReplaceAll "[^0-9.]" .result "" }}`, action=`${actionWord}`, actionRank=`${actionRank}` | ${searchArm}'')
        # The telemetry events carry no Subject, so the MTA hook rows (written by
        # services/stalwart-mta-hook.nix on dn-cc) are joined in on the queue id.
        # The hook emits queueIdDec (decimal) because the events emit it decimal
        # while the hook context itself uses hex.
        (logs "B" ''${sel} | event="mail.received" | label_format subject=`{{ .subject }}`, msgSize=`{{ .size }}`, queueId=`{{ .queueIdDec }}`, hookHelo=`{{ .helo }}`, hookMessageId=`{{ .messageId }}`, hookAuth=`{{ .authenticatedAs }}`, hookListener=`{{ .listenerId }}`, hookPort=`{{ .serverPort }}`'')
      ];
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
          options.include.names = [
            "Time"
            "trace_id"
            "queueId"
            "action"
            "actionRank"
            "subject"
            "from"
            "to"
            "remoteIp"
            "score"
          ];
        }
        {
          id = "convertFieldType";
          options.conversions = [
            {
              targetField = "actionRank";
              destinationType = "number";
            }
          ];
        }
        {
          id = "joinByField";
          options = {
            fieldName = "queueId";
            mode = "left";
          };
        }
        # Collapse the per-event rows of one SMTP session into a single row.
        # The rows are sorted by the rank first, so `lastNotNull` on the word
        # keeps the most severe action of the session (row order is preserved).
        {
          id = "sortBy";
          options.sort = [
            {
              field = "actionRank";
              desc = false;
            }
          ];
        }
        {
          id = "groupBy";
          options.fields = {
            trace_id = {
              operation = "groupby";
              aggregations = [ ];
            };
            Time = {
              operation = "aggregate";
              aggregations = [ "min" ];
            };
            action = {
              operation = "aggregate";
              aggregations = [ "lastNotNull" ];
            };
            to = {
              operation = "aggregate";
              aggregations = [ "uniqueValues" ];
            };
            from = {
              operation = "aggregate";
              aggregations = [ "lastNotNull" ];
            };
            remoteIp = {
              operation = "aggregate";
              aggregations = [ "lastNotNull" ];
            };
            subject = {
              operation = "aggregate";
              aggregations = [ "lastNotNull" ];
            };
            queueId = {
              operation = "aggregate";
              aggregations = [ "lastNotNull" ];
            };
            score = {
              operation = "aggregate";
              aggregations = [ "lastNotNull" ];
            };
          };
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              "Time 1" = true;
              trace_id = true;
            };
            renameByName = {
              Time = "Time";
              queueId = "Queue ID";
              action = "Action";
              subject = "Subject";
              from = "From";
              to = "To";
              remoteIp = "IP address";
              score = "Score";
            };
            # Grafana applies renameByName *before* indexByName, so the index
            # keys have to be the renamed (display) names.
            indexByName = {
              Time = 0;
              "Queue ID" = 1;
              Action = 2;
              Subject = 3;
              From = 4;
              To = 5;
              "IP address" = 6;
              Score = 7;
            };
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
              options = "Action";
            };
            properties = [
              {
                id = "mappings";
                value = [ statusColor ];
              }
              {
                id = "custom.cellOptions";
                value.type = "color-background";
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
            displayName = "Time";
            desc = true;
          }
        ];
      };
    }
    # One line per action, straight from the same event filters the table and
    # the stat panels use -- so the four lines always add up to what the stats
    # report for the same range.
    ((timeseries {
      id = 22;
      title = "Actions over time (accept / greylist / reject)";
      gridPos = {
        x = 0;
        y = 4;
        w = 12;
        h = 8;
      };
      stacking = "normal";
      targets = [
        {
          refId = "A";
          expr = ''sum(count_over_time(${sel} | ${queuedFilter} [$__interval]))'';
          legendFormat = "accepted";
          datasource = ds;
          queryType = "range";
        }
        {
          refId = "B";
          expr = ''sum(count_over_time(${sel} | ${greylistFilter} [$__interval]))'';
          legendFormat = "greylisted";
          datasource = ds;
          queryType = "range";
        }
        {
          refId = "C";
          expr = ''sum(count_over_time(${sel} | ${probeFilter} [$__interval]))'';
          legendFormat = "rejected (SMTP)";
          datasource = ds;
          queryType = "range";
        }
        {
          refId = "D";
          expr = ''sum(count_over_time(${sel} | ${verdictFilter} [$__interval]))'';
          legendFormat = "rejected (spam)";
          datasource = ds;
          queryType = "range";
        }
      ];
    }) // {
      fieldConfig.defaults = {
        unit = "short";
        decimals = 0;
        min = 0;
        custom = {
          drawStyle = "line";
          lineWidth = 2;
          fillOpacity = 8;
          showPoints = "auto";
          pointSize = 4;
          spanNulls = true;
          stacking.mode = "none";
        };
      };
    })
    # ---- Collapsed
    # (there is no spam traffic yet, so they are permanently empty).
    {
      id = 23;
      type = "row";
      title = "Detail panels — classifier stats / auth failures by mechanism / top offending IPs / ban reasons (collapsed)";
      collapsed = true;
      gridPos = {
        x = 0;
        y = 62;
        w = 24;
        h = 1;
      };
      panels = [
        # The classifier only reports once a spam model has been trained, which
        # needs Junk/Inbox samples -- empty until then, so they live here.
        ((promStat 17 "Classifier runs" "blue" 0 4 "spam_classify") // {
          gridPos = {
            x = 0;
            y = 63;
            w = 4;
            h = 4;
          };
        })
        ((promStat 18 "Model not ready" "orange" 4 4 "spam_model_not_ready") // {
          gridPos = {
            x = 4;
            y = 63;
            w = 4;
            h = 4;
          };
        })
        ((promStat 19 "Train completed" "green" 8 4 "spam_train_completed") // {
          gridPos = {
            x = 8;
            y = 63;
            w = 4;
            h = 4;
          };
        })
        ((barGauge {
          id = 10;
          title = "Auth failures by mechanism";
          gridPos = {
            x = 0;
            y = 67;
            w = 8;
            h = 10;
          };
          expr = "sum by (event) (count_over_time(${sel} | ${authFailFilter} [$__range]))";
          legend = "{{event}}";
        }))
        ((barGauge {
          id = 11;
          title = "Top offending IPs";
          gridPos = {
            x = 8;
            y = 67;
            w = 8;
            h = 10;
          };
          expr = "sum by (remoteIp) (count_over_time(${sel} | ${probeFilter} [$__range]))";
          legend = "{{remoteIp}}";
        }))
        ((barGauge {
          id = 12;
          title = "Ban reasons";
          gridPos = {
            x = 16;
            y = 67;
            w = 8;
            h = 10;
          };
          expr = "sum by (event) (count_over_time(${sel} | ${banFilter} [$__range]))";
          legend = "{{event}}";
        }))
        ((timeseries {
          id = 24;
          title = "Mail flow by machine (Prometheus)";
          gridPos = {
            x = 0;
            y = 79;
            w = 24;
            h = 8;
          };
          datasource = pds;
          targets = [
            (promRange "A"
              ''sum by (machine) (increase(queue_message_queued{machine=~"$machine"}[$__interval]))''
              "{{machine}} queued"
            )
            (promRange "B"
              ''sum by (machine) (increase(delivery_delivered{machine=~"$machine"}[$__interval]))''
              "{{machine}} delivered"
            )
            (promRange "C"
              ''sum by (machine) (increase(delivery_attempt_start{machine=~"$machine"}[$__interval]))''
              "{{machine}} delivery attempts"
            )
          ];
        }))
      ];
    }

    # ---- Notes ------------------------------------------------------------
    {
      id = 20;
      title = "How to read this (and why some panels stay empty)";
      type = "text";
      gridPos = {
        x = 0;
        y = 87;
        w = 24;
        h = 8;
      };
      options = {
        mode = "markdown";
        content = ''
          **Sources**

          * Loki `{service_name="stalwart"}` — one entry per Stalwart event, kept for 30 days (`retention_period = 720h`).
          * `event="mail.received"` — written by the MTA hook receiver on dn-cc (`services/stalwart-mta-hook.nix`). Stalwart calls it at the end of the SMTP `DATA` stage with the envelope and the raw headers, so these rows are one-per-message and carry the `Subject` that the telemetry events lack. Nothing else uses this stream.
          * `Message events` rows: `accept` = the message reached the queue (`queue.*message-queued`), `greylist` = `smtp.rcpt-to-greylisted` (deferred, not refused), `reject (SMTP)` = refused before or instead of queueing, `reject (spam)` = `spam.classify` with `result=reject|discard`.
          * Prometheus job `stalwart` — only counters that have already fired.

          The two tables cannot be joined: the hook answers before the verdict exists (no queue id, no score yet), and neither side carries the other's correlation id. Use `IP address` / `From` to find the same mail in both.

          **Why the spam panels may show 0 / No data**

          * `SpamSettings` on dn-cc sets only `scoreSpam = 8`; `scoreReject` and `scoreDiscard` are still at their default `0`, so Stalwart tags spam but never rejects or discards it. No verdict → no `spam.classify` reject/discard events.
          * Prometheus exports a counter **only once its value is > 0** (v0.16.26 `crates/trc/src/ipc/metrics.rs:210`: `if value > 0`). A metric that never fired has no series at all — not a scrape problem.
          * `queue.count` is an enterprise-only gauge, and `*-connection-end` is a span end that is never counted, so neither can appear here.

          **Not available at all**

          Stalwart emits no rspamd-style per-symbol detail (no rule names, no per-rule scores) — only an aggregate score plus a free-text `reason`. "Why was this flagged" therefore stops at the `Reason` column.
        '';
      };
    }
  ];
}
