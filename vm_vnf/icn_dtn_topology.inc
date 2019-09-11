vnf_names=(     'ICNDTN_seoul'    'ICNDTN_donjak'   'ICNDTN_gwanak'   'ICNDTN_donjak_pol' 'ICNDTN_donjak_fir' 'ICNDTN_gwanak_pol' 'ICNDTN_gwanak_fir' 'ICNDTN_donjak_cli' 'ICNDTN_gwanak_cli')
vnf_aliases=(   'seoul'           'donjak'          'gwanak'          'donjak_pol'        'donjak_fir'        'gwanak_pol'        'gwanak_fir'        'donjak_cli'        'gwanak_cli')
zone_names=(    'nova:vicsnf1'    'nova:vicsnf1'    'nova:vicsnf1'    'nova:vicsnf2'      'nova:vicsnf3'      'nova:vicsnf4'      'nova:vicsnf5'      'nova:vicsnf2'      'nova:vicsnf4')
vnf_mgmt_ips=(  '192.168.100.150' '192.168.100.151' '192.168.100.152' '192.168.100.153'   '192.168.100.154'   '192.168.100.155'   '192.168.100.156'   '192.168.100.157'   '192.168.100.158')
vnf_top_ips=(   '10.10.10.150'    '10.10.11.151'    '10.10.11.152'    '10.10.12.153'      '10.10.12.154'      '10.10.13.155'      '10.10.13.156'      '10.10.14.157'      '10.10.16.158')
vnf_bottom_ips=('10.10.11.150'    '10.10.12.151'    '10.10.13.152'    '10.10.14.153'      '10.10.15.154'      '10.10.16.155'      '10.10.17.156'      '10.10.15.157'      '10.10.17.158')
vnf_top_vls=(   'ndn_10.x'        'ndn_11.x'        'ndn_11.x'        'ndn_12.x'          'ndn_12.x'          'ndn_13.x'          'ndn_13.x'          'ndn_14.x'          'ndn_16.x')
vnf_bottom_vls=('ndn_11.x'        'ndn_12.x'        'ndn_13.x'        'ndn_14.x'          'ndn_15.x'          'ndn_16.x'          'ndn_17.x'          'ndn_15.x'          'ndn_17.x')
vnf_neighbor_ips=(\
'10.10.11.151:10.10.11.152' \
'10.10.11.150:10.10.12.153:10.10.12.154' \
'10.10.11.150:10.10.13.155:10.10.13.156' \
'10.10.12.151:10.10.14.157' \
'10.10.12.151:10.10.15.157' \
'10.10.13.152:10.10.16.158' \
'10.10.13.152:10.10.17.158' \
'10.10.14.153:10.10.15.154' \
'10.10.16.155:10.10.17.156')

vnf_neighbor_names=(\
'donjak:gwanak' \
'seoul:donjak_pol:donjak_fir' \
'seoul:gwanak_pol:gwanak_fir' \
'donjak:donjak_cli' \
'donjak:donjak_cli' \
'gwanak:gwanak_cli' \
'gwanak:gwanak_cli' \
'donjak_pol:donjak_fir' \
'gwanak_pol:gwanak_fir')

vnf_site_route_names=(\
'seoul:center' \
'seoul\\/donjak:center' \
'seoul\\/gwanak:center' \
'seoul\\/donjak\\/donjak_pol:center' \
'seoul\\/donjak\\/donjak_fir:center' \
'seoul\\/gwanak\\/gwanak_pol:center' \
'seoul\\/gwanak\\/gwanak_fir:center' \
'seoul\\/donjak\\/donjak_pol\\/donjak_cli:agent' \
'seoul\\/gwanak\\/gwanak_pol\\/gwanak_cli:agent')

vnf_neighbor_routes=(\
'seoul\\/donjak#center:seoul\\/gwanak#center' \
'seoul#center:seoul\\/donjak\\/donjak_pol#center:seoul\\/donjak\\/donjak_fir#center' \
'seoul#center:seoul\\/gwanak\\/gwanak_pol#center:seoul\\/gwanak\\/gwanak_fir#center' \
'seoul\\/donjak#center:seoul\\/donjak\\/donjak_pol\\/donjak_cli#agent' \
'seoul\\/donjak#center:seoul\\/donjak\\/donjak_fir\\/donjak_cli#agent' \
'seoul\\/gwanak#center:seoul\\/gwanak\\/gwanak_pol\\/gwanak_cli#agent' \
'seoul\\/gwanak#center:seoul\\/gwanak\\/gwanak_fir\\/gwanak_cli#agent' \
'seoul\\/donjak\\/donjak_pol#center:seoul\\/donjak\\/donjak_fir#center' \
'seoul\\/gwanak\\/gwanak_pol#center:seoul\\/gwanak\\/gwanak_fir#center')

vnf_prefixes=(\
'seoul\\/center' \
'seoul\\/donjak\\/center' \
'seoul\\/gwanak\\/center' \
'seoul\\/donjak\\/police' \
'seoul\\/donjak\\/fire' \
'seoul\\/gwanak\\/police' \
'seoul\\/gwanak\\/fire' \
'seoul\\/donjak\\/police\\/client:seoul\\/donjak\\/fire\\/client' \
'seoul\\/gwanak\\/police\\/client:seoul\\/gwanak\\/fire\\/client')
