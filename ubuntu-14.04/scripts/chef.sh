#!/bin/sh
which chef-client || wget -qO- https://www.opscode.com/chef/install.sh | bash
