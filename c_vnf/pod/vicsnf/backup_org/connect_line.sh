#!/bin/bash

kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face create remote tcp4://dongjak'
kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face create remote tcp4://gangnam'

kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://gangnam'
kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://dongjak_pf'
kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face create remote tcp4://dongjak_h'

kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_pu1'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_pu2'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_fu1'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face create remote tcp4://dongjak_fu2'
kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face create remote tcp4://dongjak_hu1'
kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face create remote tcp4://dongjak_hu2'

kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face create remote tcp4://gangnam_pf'
kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face create remote tcp4://gangnam_h'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_pu1'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_pu2'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_fu1'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face create remote tcp4://gangnam_fu2'
kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face create remote tcp4://gangnam_hu1'
kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face create remote tcp4://gangnam_hu2'



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