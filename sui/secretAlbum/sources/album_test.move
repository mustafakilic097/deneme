#[test_only]
module secretAlbum::album_test {

    use sui::test_scenario;
    use secretAlbum::album::{Self, AlbumHub, Album};

    #[test]
    fun test_create_album() {
        let owner = @0xA;
        let user1 = @0xB;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            album::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, owner);
        {
            let album_hub = test_scenario::take_from_sender<AlbumHub>(scenario);

            album::create_album(b"Album1", b"http://example.com/image.jpg", &mut album_hub, test_scenario::ctx(scenario));

            assert!(!test_scenario::has_most_recent_for_sender<Album>(scenario), 0);

            test_scenario::return_to_sender(scenario, album_hub);
        };

        test_scenario::next_tx(scenario, user1);
        {
            assert!(test_scenario::has_most_recent_for_sender<AlbumHub>(scenario), 0);
        };

        test_scenario::end(scenario_val);
    }
}
