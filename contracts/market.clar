(use-trait nft-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-constant owner tx-sender)
(define-constant err-expiry-in-past (err u1000))
(define-constant err-price-zero (err u1001))
(define-constant err-unknown-listing (err u1002))
(define-constant err-unauthorised (err u1003))
(define-constant err-maker-taker-equal (err u1004))
(define-constant err-listing-expired (err u1005))

(define-map listings
    uint
    {
        maker : principal,
        token-id : uint,
        token-contract : principal,
        expiry : uint,
        price : uint,
    }
)

(define-data-var listing-nonce uint u0)


(define-private (transfer-nft (token-contract <nft-trait>) (token-id uint) (sender principal) (recipient principal)) 
(contract-call? token-contract transfer token-id sender recipient)
)

(define-public (list-asset (token-contract <nft-trait>) (nft-asset { token-id: uint, expiry: uint, price: uint}))
    (let ((listing-id (var-get listing-nonce)))
        (asserts! (> (get expiry nft-asset) block-height) err-expiry-in-past)
        (asserts! (> (get price nft-asset) u0) err-price-zero)
        (try! (transfer-nft token-contract (get token-id nft-asset) tx-sender (as-contract tx-sender)))
        (map-set listings listing-id (merge {maker: tx-sender, token-contract: (contract-of token-contract)} nft-asset))
        (var-set listing-nonce (+ listing-id u1))
        (ok listing-id)
    )
)

(define-read-only (get-listing (listing-id uint))
    (map-get? listings listing-id)
)

(define-public (cancel-listing (listing-id uint) (token-contract <nft-trait>))
    (let (
        (listing (unwrap! (map-get? listings listing-id) err-unknown-listing))
        (maker (get maker listing))
        )
        (asserts! (is-eq maker tx-sender) err-unauthorised)
        (map-delete listings listing-id)
        (as-contract (transfer-nft token-contract (get token-id listing) tx-sender maker))
    )
)

(define-private (assert-can-fulfil (token-contract principal) (listing {maker: principal, token-id: uint, token-contract: principal, expiry: uint, price: uint}))
    (begin
        (asserts! (not (is-eq (get maker listing) tx-sender)) err-maker-taker-equal)
        (asserts! (< block-height (get expiry listing)) err-listing-expired)
        (ok true)
    )
)

(define-public (fulfil-listing-stx (listing-id uint) (token-contract <nft-trait>))
    (let (
        (listing (unwrap! (map-get? listings listing-id) err-unknown-listing))
        (taker tx-sender)
        )
        (try! (assert-can-fulfil (contract-of token-contract)  listing))
        (try! (as-contract (transfer-nft token-contract (get token-id listing) tx-sender taker)))
        (try! (stx-transfer? (get price listing) taker (get maker listing)))
        (map-delete listings listing-id)
        (ok listing-id)
    )
)