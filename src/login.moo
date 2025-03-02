object LOGIN
    name: "Login Service"
    parent: ROOT
    owner: ARCH_WIZARD
    readable: true

    property blank_command (owner: ARCH_WIZARD, flags: "r") = "welcome";
    property bogus_command (owner: ARCH_WIZARD, flags: "r") = "?";
    property welcome_message (owner: ARCH_WIZARD, flags: "rc") = {"## Welcome to the _mooR_ *Cowbell* core.", "", "connect with `archwizard` `test` to log in.", "", "You will probably want to change this text which is stored in $login.welcome_message property."};

    verb _match_player (this none this) owner: ARCH_WIZARD flags: "rxd"
        ":_match_player(name)";
        "This is the matching routine used by @connect.";
        "returns either a valid player corresponding to name or $failed_match.";
        name = args[1];
        if (valid(candidate = name:literal_object()) && is_player(candidate))
          return candidate;
        endif
        "Simple brute force player name scan without considering aliases. Other cores have a $player_db, we might do the same when we grow up.";
        for candidate in (players())
          if (candidate.name == name)
            return candidate;
          endif
        endfor
        return $failed_match;
    endverb

    verb "co*nnect @co*nnect" (any none any) owner: ARCH_WIZARD flags: "rxd"
        "$login:connect(player-name [, password])";
        " => 0 (for failed connections)";
        " => objnum (for successful connections)";
        caller == #0 || caller == this || raise(E_PERM);
        "Check arguments, print usage notice if necessary";
        try
          {name, ?password = 0} = args;
          name = strsub(name, " ", "_");
        except (E_ARGS)
          notify(player, tostr("Usage:  ", verb, " <existing-player-name> <password>"));
          return 0;
        endtry
        "Is our candidate name invalid?";
        if (!valid(candidate = orig_candidate = this:_match_player(name)))
          raise(E_INVARG, tostr("`", name, "' matches no player name."));
        endif
        "We have a valid candidate, so we can now attempt to challenge it.";
        "We assume the password is a $password frob and has a :challenge verb available...";
        p_obj = candidate.password;
        if (!p_obj:challenge(password))
          server_log(tostr("FAILED CONNECT: ", name, " (", candidate, ") on ", connection_name(player)));
          raise(E_INVARG, "Invalid password.");
        endif
        "TODO: block lists, guests, etc";
        "Log the player in!";
        return candidate;
    endverb

    verb parse_command (this none this) owner: ARCH_WIZARD flags: "rxd"
        ":parse_command(@args) => {verb, args}";
        "Given the args from #0:do_login_command,";
        "  returns the actual $login verb to call and the args to use.";
        "Commands available to not-logged-in users should be located on this object and given the verb_args \"any none any\"";
        caller != #0 && caller != this && return E_PERM;
        !args && return {this.blank_command, @args};
        if ((verb = args[1]) && !verb:is_numeric())
          for i in ({this, @this:ancestors()})
            try
              if (verb_args(i, verb) == {"any", "none", "any"} && index(verb_info(i, verb)[2], "x"))
                return args;
              endif
            except (ANY)
              continue i;
            endtry
          endfor
        endif
        return {this.bogus_command, @args};
    endverb

    verb welcome (any none any) owner: ARCH_WIZARD flags: "rxd"
        caller != #0 && caller != this && raise(E_PERM);
        { notify(player, line) for line in (this.welcome_message) };
    endverb
endobject
