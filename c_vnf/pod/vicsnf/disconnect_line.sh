#!/bin/bash

kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face destroy tcp4://seoul'
kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face destroy tcp4://gyeonggi'
kubectl -n vicsnet exec -it korea -- bash -c 'nfdc face destroy tcp4://korea-hq'

kubectl -n vicsnet exec -it seoul -- bash -c 'nfdc face destroy tcp4://dongjak'
kubectl -n vicsnet exec -it seoul -- bash -c 'nfdc face destroy tcp4://gangnam'
kubectl -n vicsnet exec -it gyeonggi -- bash -c 'nfdc face destroy tcp4://seongnam'


kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face destroy tcp4://gangnam'
kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face destroy tcp4://dongjak-pf'
kubectl -n vicsnet exec -it dongjak -- bash -c 'nfdc face destroy tcp4://dongjak-h'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face destroy tcp4://dongjak-pu1'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face destroy tcp4://dongjak-pu2'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face destroy tcp4://dongjak-fu1'
kubectl -n vicsnet exec -it dongjak-pf -- bash -c 'nfdc face destroy tcp4://dongjak-fu2'
kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face destroy tcp4://dongjak-hu1'
kubectl -n vicsnet exec -it dongjak-h -- bash -c 'nfdc face destroy tcp4://dongjak-hu2'

kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face destroy tcp4://gangnam-pf'
kubectl -n vicsnet exec -it gangnam -- bash -c 'nfdc face destroy tcp4://gangnam-h'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face destroy tcp4://gangnam-pu1'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face destroy tcp4://gangnam-pu2'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face destroy tcp4://gangnam-fu1'
kubectl -n vicsnet exec -it gangnam-pf -- bash -c 'nfdc face destroy tcp4://gangnam-fu2'
kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face destroy tcp4://gangnam-hu1'
kubectl -n vicsnet exec -it gangnam-h -- bash -c 'nfdc face destroy tcp4://gangnam-hu2'


kubectl -n vicsnet exec -it seongnam -- bash -c 'nfdc face destroy tcp4://seongnam-pfh'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face destroy tcp4://seongnam-pu1'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face destroy tcp4://seongnam-pu2'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face destroy tcp4://seongnam-fu1'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face destroy tcp4://seongnam-fu2'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face destroy tcp4://seongnam-hu1'
kubectl -n vicsnet exec -it seongnam-pfh -- bash -c 'nfdc face destroy tcp4://seongnam-hu2'