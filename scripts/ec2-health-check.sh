#!/bin/bash
REPORT_DATE=$(date)
HOSTNAME_VALUE=$(hostname)
CURRENT_USER=$(whoami)
PRIVATE_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s --max-time 5 https://checkip.amazonaws.com 2>/dev/null)

PASS_COUNT=0
WARNING_COUNT=0

print_section() {
echo ""
echo "========================================"
echo "$1"
echo "========================================"
}

mark_pass() {
echo "[PASS] $1"
PASS_COUNT=$((PASS_COUNT + 1))
}

mark_warning() {
echo "[WARNING] $1"
WARNING_COUNT=$((WARNING_COUNT + 1))
}

echo "========================================"
echo " PROLEAP EC2 HEALTH CHECK REPORT"
echo "========================================"
echo "Report Date : $REPORT_DATE"
echo "Hostname : $HOSTNAME_VALUE"
echo "Current User: $CURRENT_USER"
echo "Private IP : $PRIVATE_IP"
echo "Public IP : ${PUBLIC_IP:-Unable to detect}"

print_section "1. OPERATING SYSTEM INFORMATION"

if [ -f /etc/os-release ]; then
grep -E '^(NAME|VERSION)=' /etc/os-release
mark_pass "Operating system information collected"
else
mark_warning "Unable to read operating system information"
fi

print_section "2. SYSTEM UPTIME"

uptime

if uptime >/dev/null 2>&1; then
mark_pass "System uptime command executed successfully"
else
mark_warning "Unable to collect system uptime"
fi

print_section "3. CPU LOAD"

uptime | awk -F'load average:' '{print "Load Average:" $2}'
CPU_COUNT=$(nproc)
LOAD_ONE=$(awk '{print $1}' /proc/loadavg)

echo "CPU Cores : $CPU_COUNT"
echo "1-Minute Load: $LOAD_ONE"

if awk "BEGIN {exit !($LOAD_ONE < $CPU_COUNT)}"; then
mark_pass "CPU load is below the available CPU core count"
else
mark_warning "CPU load is equal to or above the CPU core count"
fi

print_section "4. MEMORY USAGE"

free -h
MEMORY_USAGE=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
echo "Memory Usage: $MEMORY_USAGE%"

if [ "$MEMORY_USAGE" -lt 80 ]; then
mark_pass "Memory usage is below 80%"
else
mark_warning "Memory usage is 80% or higher"
fi

print_section "5. ROOT DISK USAGE"

df -h /
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
echo "Root Disk Usage: $DISK_USAGE%"

if [ "$DISK_USAGE" -lt 80 ]; then
mark_pass "Root disk usage is below 80%"
else
mark_warning "Root disk usage is 80% or higher"
fi

print_section "6. TOP 5 MEMORY-CONSUMING PROCESSES"

ps aux --sort=-%mem | head -6
mark_pass "Top memory-consuming processes collected"

print_section "7. NGINX SERVICE STATUS"

if systemctl is-active --quiet nginx; then
systemctl is-active nginx
mark_pass "Nginx service is running"
else
systemctl is-active nginx 2>/dev/null || true
mark_warning "Nginx service is not running"
fi

print_section "8. PORT 80 STATUS"

if ss -tulpn 2>/dev/null | grep -q ':80'; then
ss -tulpn 2>/dev/null | grep ':80'
mark_pass "Port 80 is listening"
else
mark_warning "Port 80 is not listening"
fi

print_section "9. LOCALHOST WEBSITE TEST"

LOCAL_RESPONSE=$(curl -s --max-time 5 localhost)

if echo "$LOCAL_RESPONSE" | grep -q "ProLEAP EC2 Server is Running"; then
echo "$LOCAL_RESPONSE" | head -5
mark_pass "Localhost returned the expected ProLEAP web page"
else
mark_warning "Localhost did not return the expected ProLEAP web page"
fi

print_section "10. PUBLIC WEBSITE TEST"

if [ -n "$PUBLIC_IP" ]; then
PUBLIC_RESPONSE=$(curl -s --max-time 8 "http://$PUBLIC_IP")

if echo "$PUBLIC_RESPONSE" | grep -q "ProLEAP EC2 Server is Running"; then
echo "Public URL: http://$PUBLIC_IP"
mark_pass "Public website returned the expected ProLEAP page"
else
mark_warning "Public website is not returning the expected page"
fi
else
mark_warning "Public IP could not be detected"
fi

print_section "11. INTERNET CONNECTIVITY TEST"

if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
mark_pass "Internet connectivity is available"
else
mark_warning "Internet connectivity test failed"
fi

print_section "12. DNS RESOLUTION TEST"

if getent hosts amazon.com >/dev/null 2>&1; then
getent hosts amazon.com | head -1
mark_pass "DNS resolution is working"
else
mark_warning "DNS resolution failed"
fi

print_section "FINAL HEALTH SUMMARY"

echo "Passed Checks : $PASS_COUNT"
echo "Warnings : $WARNING_COUNT"

if [ "$WARNING_COUNT" -eq 0 ]; then
echo "Overall Status: HEALTHY"
EXIT_CODE=0
else
echo "Overall Status: ATTENTION REQUIRED"
EXIT_CODE=1
fi

echo ""
echo "========================================"
echo " HEALTH CHECK COMPLETED"
echo "========================================"

exit "$EXIT_CODE"
