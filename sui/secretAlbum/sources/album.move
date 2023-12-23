module secretAlbum::album {
    // Import'lar burada yapiliyor
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::object_table::{Self, ObjectTable};
    use sui::event;

    // Olusabilecek hatalar icin bu sabitleri atiyoruz
    const NOT_THE_OWNER: u64 = 0;
    const INSUFFICIENT_FUNDS: u64 = 1;
    const MIN_album_COST: u64 = 1;

    // Album struct'imizi burada tanimladik
    struct Album has key, store {
        id: UID,
        owner: address,
        title: String,
        img_url: Url,
    }

    // Album merkezimiz burasi olacak
    struct AlbumHub has key {
        id: UID,
        owner: address,
        counter: u64,
        albums: ObjectTable<u64, Album>,
    }

    // Emmit ederken kullanilacak struct'lar
    struct AlbumCreated has copy, drop {
        id: ID,
        owner: address,
        title: String,
        img_url: Url,
    }

    struct TitleUpdated has copy, drop {
        owner: address,
        img_url: Url,
        new_title: String
    }

    // Albumu acan init fonksiyonu
    fun init(ctx: &mut TxContext) {
        transfer::share_object(
            AlbumHub {
                id: object::new(ctx),
                owner: tx_context::sender(ctx),
                counter: 0,
                albums: object_table::new(ctx),
            }
        );
    }

    // Yeni bir album olulturmak icin kullanilan fonksiyon
    public entry fun create_album(
        title: vector<u8>,
        img_url: vector<u8>,
        albumHub: &mut AlbumHub,
        ctx: &mut TxContext
    ) {
        // Yeni eklenecek image url icin counter 1 arttiriliyor
        albumHub.counter = albumHub.counter + 1;
        // Yeni bir id olusturuluyor
        let id = object::new(ctx);

        // Bu kisim frontende gidecek 
        event::emit(
            AlbumCreated { 
                id: object::uid_to_inner(&id), 
                owner: tx_context::sender(ctx), 
                title: string::utf8(title), 
                img_url: url::new_unsafe_from_bytes(img_url),
            }
        );

        // Nihai Album'u burada olusturuyoruz
        let oneAlbum = Album {
            id: id,
            owner: tx_context::sender(ctx),
            title: string::utf8(title),
            img_url: url::new_unsafe_from_bytes(img_url),
        };

        // Object table'a yeni image'i atiyor
        object_table::add(&mut albumHub.albums, albumHub.counter, oneAlbum);
    }

    // Title'i guncellemek icin kullanilan fonksiyon
    public entry fun update_album_title(albumHub: &mut AlbumHub, new_title: vector<u8>, id: u64, ctx: &mut TxContext) {
        // albumleri al ve degistir tanimi
        let user_album = object_table::borrow_mut(&mut albumHub.albums, id);
        // album sahibi degilse hata dondurur
        assert!(tx_context::sender(ctx) == user_album.owner, NOT_THE_OWNER);
        // Eski title'i degistirip cikartiyoruz
        // let old_value = option::swap_or_fill(&mut user_album.title, string::utf8(new_title));
        let old_value = user_album.title;
        user_album.title = string::utf8(new_title);
        //Guncelleme bilgisini frontend icin emmit ediyoruz
        event::emit(TitleUpdated {
            owner: user_album.owner,
            img_url: user_album.img_url,
            new_title: string::utf8(new_title)
        });

        //Eski title burada tamamen cikartiliyor
        _ = old_value;
    }

    // Bu fonksiyon belirtilen id icin album infosunu getiriyor
    public fun get_album_info(albumHub: &AlbumHub, id: u64): (
        address,
        String,
        Url,
    ) {
        let album = object_table::borrow(&albumHub.albums, id);
        (
            album.owner,
            album.title,
            album.img_url,
        )
    }
    #[test_only]
    // Not public by default
    public fun init_for_testing(ctx: &mut TxContext){
        init(ctx);
    }
}