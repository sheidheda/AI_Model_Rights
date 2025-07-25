;; AI Model Rights NFT Registry
;; Tokenizes AI model ownership and usage rights as NFTs

;; Define NFT
(define-non-fungible-token ai-model-rights uint)

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-already-exists (err u104))

;; Define data variables
(define-data-var token-id-counter uint u0)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Define maps
(define-map token-metadata
    uint
    {
        model-name: (string-utf8 100),
        model-hash: (buff 32),
        creator: principal,
        creation-date: uint,
        license-type: (string-utf8 50),
        usage-fee: uint
    }
)

(define-map token-listings
    uint
    {
        price: uint,
        listed: bool
    }
)

(define-map usage-licenses
    { token-id: uint, licensee: principal }
    { 
        expiry-block: uint,
        uses-remaining: uint
    }
)

;; Read-only functions
(define-read-only (get-token-metadata (token-id uint))
    (map-get? token-metadata token-id)
)

(define-read-only (get-listing (token-id uint))
    (map-get? token-listings token-id)
)

(define-read-only (get-usage-license (token-id uint) (licensee principal))
    (map-get? usage-licenses { token-id: token-id, licensee: licensee })
)

(define-read-only (get-token-owner (token-id uint))
    (nft-get-owner? ai-model-rights token-id)
)

;; Public functions
(define-public (mint-model-nft 
    (model-name (string-utf8 100))
    (model-hash (buff 32))
    (license-type (string-utf8 50))
    (usage-fee uint))
    (let
        (
            (token-id (+ (var-get token-id-counter) u1))
        )
        (try! (nft-mint? ai-model-rights token-id tx-sender))
        (map-set token-metadata token-id {
            model-name: model-name,
            model-hash: model-hash,
            creator: tx-sender,
            creation-date: stacks-block-height,
            license-type: license-type,
            usage-fee: usage-fee
        })
        (var-set token-id-counter token-id)
        (ok token-id)
    )
)

(define-public (list-for-sale (token-id uint) (price uint))
    (let
        (
            (token-owner (unwrap! (get-token-owner token-id) err-not-token-owner))
        )
        (asserts! (is-eq tx-sender token-owner) err-not-token-owner)
        (map-set token-listings token-id { price: price, listed: true })
        (ok true)
    )
)

(define-public (unlist (token-id uint))
    (let
        (
            (token-owner (unwrap! (get-token-owner token-id) err-not-token-owner))
        )
        (asserts! (is-eq tx-sender token-owner) err-not-token-owner)
        (map-set token-listings token-id { price: u0, listed: false })
        (ok true)
    )
)

(define-public (buy-model-nft (token-id uint))
    (let
        (
            (listing (unwrap! (get-listing token-id) err-listing-not-found))
            (token-owner (unwrap! (get-token-owner token-id) err-not-token-owner))
            (metadata (unwrap! (get-token-metadata token-id) err-listing-not-found))
            (platform-fee (/ (* (get price listing) (var-get platform-fee-percentage)) u100))
            (seller-amount (- (get price listing) platform-fee))
        )
        (asserts! (get listed listing) err-listing-not-found)
        (try! (stx-transfer? platform-fee tx-sender contract-owner))
        (try! (stx-transfer? seller-amount tx-sender token-owner))
        (try! (nft-transfer? ai-model-rights token-id token-owner tx-sender))
        (map-set token-listings token-id { price: u0, listed: false })
        (ok true)
    )
)

(define-public (purchase-usage-license (token-id uint) (duration-blocks uint) (max-uses uint))
    (let
        (
            (metadata (unwrap! (get-token-metadata token-id) err-listing-not-found))
            (token-owner (unwrap! (get-token-owner token-id) err-not-token-owner))
            (total-fee (* (get usage-fee metadata) max-uses))
            (creator-fee (/ (* total-fee u70) u100)) ;; 70% to creator
            (owner-fee (- total-fee creator-fee))
        )
        (try! (stx-transfer? creator-fee tx-sender (get creator metadata)))
        (if (not (is-eq token-owner (get creator metadata)))
            (try! (stx-transfer? owner-fee tx-sender token-owner))
            true
        )
        (map-set usage-licenses 
            { token-id: token-id, licensee: tx-sender }
            { 
                expiry-block: (+ stacks-block-height duration-blocks),
                uses-remaining: max-uses
            }
        )
        (ok true)
    )
)