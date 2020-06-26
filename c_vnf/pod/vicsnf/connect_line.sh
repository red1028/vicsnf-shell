#!/bin/bash

kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face create remote tcp4://seoul persistency permanent'
kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face create remote tcp4://gyeonggi persistency permanent'
kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face create remote tcp4://korea-hq persistency permanent'

kubectl -n vicsnet exec -it seoul -- bash -c 'nfdc face create remote tcp4://dongjak persistency permanent'
kubectl -n vicsnet exec -it seoul -- bash -c 'nfdc face create remote tcp4://gangnam persistency permanent'
kubectl -n vicsnet exec -it gyeonggi -- bash -c 'nfdc face create remote tcp4://seongnam persistency permanent'


kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://gangnam persistency permanent'
kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://dongjak-pf persistency permanent'
kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://dongjak-h persistency permanent'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak-pu1 persistency permanent'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak-pu2 persistency permanent'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak-fu1 persistency permanent'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak-fu2 persistency permanent'
kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face create remote tcp4://dongjak-hu1 persistency permanent'
kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face create remote tcp4://dongjak-hu2 persistency permanent'

kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face create remote tcp4://gangnam-pf persistency permanent'
kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face create remote tcp4://gangnam-h persistency permanent'
#kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face create remote tcp4://korea-hq persistency permanent'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam-pu1 persistency permanent'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam-pu2 persistency permanent'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam-fu1 persistency permanent'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam-fu2 persistency permanent'
kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face create remote tcp4://gangnam-hu1 persistency permanent'
kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face create remote tcp4://gangnam-hu2 persistency permanent'


kubectl -n vicsnet exec -it seongnam -- bash -c 'nfdc face create remote tcp4://seongnam-pfh persistency permanent'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face create remote tcp4://seongnam-pu1 persistency permanent'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face create remote tcp4://seongnam-pu2 persistency permanent'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face create remote tcp4://seongnam-fu1 persistency permanent'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face create remote tcp4://seongnam-fu2 persistency permanent'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face create remote tcp4://seongnam-hu1 persistency permanent'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face create remote tcp4://seongnam-hu2 persistency permanent'


###!/bin/bash
##
##kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face create remote tcp4://dongjak persistency permanent'
##kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face create remote tcp4://gangnam persistency permanent'
##
##kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://gangnam persistency permanent'
##kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://dongjak_pf persistency permanent'
##kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://dongjak_h persistency permanent'
##
##kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_pu1 persistency permanent'
##kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_pu2 persistency permanent'
##kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_fu1 persistency permanent'
##kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_fu2 persistency permanent'
##kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face create remote tcp4://dongjak_hu1 persistency permanent'
##kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face create remote tcp4://dongjak_hu2 persistency permanent'
##
##kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face create remote tcp4://gangnam_pf persistency permanent'
##kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face create remote tcp4://gangnam_h persistency permanent'
##kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_pu1 persistency permanent'
##kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_pu2 persistency permanent'
##kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_fu1 persistency permanent'
##kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_fu2 persistency permanent'
##kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face create remote tcp4://gangnam_hu1 persistency permanent'
##kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face create remote tcp4://gangnam_hu2 persistency permanent'
