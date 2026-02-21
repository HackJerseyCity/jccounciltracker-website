require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "public access returns 200" do
    get search_path
    assert_response :success
  end

  test "no filters shows instructional message" do
    get search_path
    assert_select "p", text: /Use the filters above/
  end

  test "text query matches items by title substring" do
    get search_path, params: { q: "Fees and Charges" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "text query is case-insensitive" do
    get search_path, params: { q: "fees and charges" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "text query with no match shows empty state" do
    get search_path, params: { q: "xyznonexistent" }
    assert_response :success
    assert_select "p", text: /No agenda items match/
  end

  test "SQL LIKE wildcard characters are escaped" do
    get search_path, params: { q: "100%" }
    assert_response :success
  end

  test "file number filter finds by partial match" do
    get search_path, params: { file_number: "26-009" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "file number filter finds by full match" do
    get search_path, params: { file_number: "Ord. 26-009" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "council member filter returns items they voted on" do
    get search_path, params: { council_member_id: council_members(:ridley).id }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "vote column shown when council member selected" do
    get search_path, params: { council_member_id: council_members(:ridley).id }
    assert_select "th", text: /Vote/
  end

  test "vote column hidden without council member" do
    get search_path, params: { q: "Fees" }
    assert_select "th", text: /Vote/, count: 0
  end

  test "vote position with council member filters by position" do
    get search_path, params: { council_member_id: council_members(:ridley).id, vote_position: "aye" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/

    get search_path, params: { council_member_id: council_members(:ridley).id, vote_position: "nay" }
    assert_response :success
    assert_select "p", text: /No agenda items match/
  end

  test "vote position without council member is ignored" do
    get search_path, params: { vote_position: "aye" }
    assert_response :success
    assert_select "p", text: /Use the filters above/
  end

  test "tag filter finds tagged items" do
    get search_path, params: { tag_id: tags(:budget).id }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "tag filter excludes untagged items" do
    get search_path, params: { tag_id: tags(:housing).id }
    assert_response :success
    assert_select "p", text: /No agenda items match/
  end

  test "date from filter includes items on or after date" do
    get search_path, params: { date_from: "2026-02-25" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "date to filter excludes items after date" do
    get search_path, params: { date_to: "2026-01-01" }
    assert_response :success
    assert_select "p", text: /No agenda items match/
  end

  test "invalid date does not error" do
    get search_path, params: { date_from: "not-a-date" }
    assert_response :success
  end

  test "result filter matches items with that result" do
    get search_path, params: { result: "approved" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/
  end

  test "invalid result is ignored" do
    get search_path, params: { result: "invalid_value" }
    assert_response :success
    assert_select "p", text: /Use the filters above/
  end

  test "combined filters compose together" do
    get search_path, params: { q: "Fees", tag_id: tags(:budget).id, result: "approved" }
    assert_response :success
    assert_select "td", text: /Fees and Charges/

    get search_path, params: { q: "Fees", tag_id: tags(:housing).id }
    assert_response :success
    assert_select "p", text: /No agenda items match/
  end

  test "pagination with page 1 works" do
    get search_path, params: { q: "Ordinance", page: 1 }
    assert_response :success
  end

  test "negative page defaults to 1" do
    get search_path, params: { q: "Ordinance", page: -5 }
    assert_response :success
  end

  test "items from draft versions excluded from results" do
    agenda_versions(:regular_meeting_v1).update!(status: :draft)

    get search_path, params: { q: "Fees" }
    assert_response :success
    assert_select "p", text: /No agenda items match/
  end
end
