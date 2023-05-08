(impl-trait 'ST1NXBK3K5YYMD6FD41MVNP3JS1GABZ8TRVX023PT.nft-trait.nft-trait)

(define-constant err-token-id-failure (err u101))
(define-constant err-not-token-owner (err u102))

(define-map token-uri uint (string-ascii 50))
(define-non-fungible-token ignitus uint)
(define-data-var token-id-nonce uint u0)

(define-read-only (get-last-token-id)
	(ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
	(ok (map-get? token-uri token-id))
)

(define-read-only (get-owner (token-id uint))
	(ok (nft-get-owner? ignitus token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
	(begin
		(asserts! (is-eq tx-sender sender) err-not-token-owner)
		(nft-transfer? ignitus token-id sender recipient)
	)
)

(define-public (mint (recipient principal) (uri (string-ascii 50)))
	(let ((token-id (+ (var-get token-id-nonce) u1)))
		(try! (nft-mint? ignitus token-id recipient))
		(asserts! (var-set token-id-nonce token-id) err-token-id-failure)
		(map-set token-uri token-id uri)
		(ok token-id)
	)
)