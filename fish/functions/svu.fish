function svu
    set -l gateway "10.1.0.1"
    set -l username Username
    set -l password password
    set -l mac "<Your Mac>"

    set -l green (set_color green)
    set -l red (set_color red)
    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l normal (set_color normal)
    set -l bold (set_color --bold)

    clear

    echo
    echo "$cyan$bold South Valley University $normal"
    echo "$cyan Network Authentication $normal"
    echo

    echo "$yellow [1/3] Changing MAC address... $normal"

    sudo ip link set wlan0 down
    or return 1

    sudo macchanger wlan0 -m "$mac"
    or return 1

    sudo ip link set wlan0 up
    or return 1

    echo "$green [+] MAC address configured $normal"

    echo "$yellow [2/3] Connecting to gateway... $normal"

    if not curl -s --connect-timeout 5 "http://$gateway/" >/dev/null
        echo "$red [-] Gateway unreachable $normal"
        return 1
    end

    echo "$green [+] Gateway reachable $normal"

    echo "$yellow [3/3] Authenticating... $normal"

    set -l response (curl -sS --max-time 15 \
        --get "http://$gateway/login" \
        --data-urlencode "dst=" \
        --data-urlencode "popup=true" \
        --data-urlencode "username=$username" \
        --data-urlencode "password=$password")

    if string match -q '*تم تسجيل الدخول!*' "$response"
        echo "$green$bold [+] Login successful! $normal"
        echo "$cyan [+] Network status: http://$gateway/status $normal"
    else
        echo "$red [-] Login failed $normal"
    end

    echo

    echo "$yellow [4/4] Fetching network status... $normal"

    set -l network_status (curl -fsS --max-time 10 \
        "http://$gateway/status")

    if test $pipestatus[1] -ne 0
        echo "$red [-] Unable to fetch network status $normal"
        return 1
    end

    set -l username (string match -r --groups-only 'اسم المستخدم:</td>\s*<td class="value">([^<]+)' "$network_status")
    set -l ip (string match -r --groups-only 'عنوان IP:</td>\s*<td class="value">([^<]+)' "$network_status")
    set -l traffic (string match -r --groups-only 'التحميل / الرفع:</td>\s*<td class="value">([^<]+)' "$network_status")
    set -l uptime (string match -r --groups-only 'وقت الاتصال:</td>\s*<td class="value">([^<]+)' "$network_status")
    echo
    echo "$green$bold       CONNECTION STATUS $normal"
    echo
    echo "  Username : $cyan$username$normal"
    echo "  IP       : $cyan$ip$normal"
    echo "  Traffic  : $cyan$traffic$normal"
    echo "  Uptime   : $cyan$uptime$normal"
    echo

end
