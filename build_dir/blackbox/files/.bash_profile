ip -br addr show
echo
echo "Failed units:"
systemctl --failed --no-legend --no-pager
echo