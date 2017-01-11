# restrict-iptables-by-country
Restrict iptables by country

# Dependencies:
 * iptables
 * bc
 * wget
 * https://github.com/rudimeier/bash_ini_parser

# Installing:
 * `git clone https://github.com/kirbo/restrict-iptables-by-country.git`
 * `cd restrict-iptables-by-country`
 * `git submodule update --init`
 * Create `config.ini`, there are two examples `config.ini-allow.sample` and `config.ini-block.sample` that you can modify
 * `bash ribc.sh INSTALL`
 * `/etc/init.d/ribc start`

