require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "new shows sign up form" do
    get new_signup_path
    assert_response :success
    assert_select "h1", text: "Create your account"
  end

  test "create with valid params creates user and signs in" do
    assert_difference "User.count", 1 do
      post signup_path, params: {
        user: {
          name: "New User",
          email_address: "newuser@example.com",
          password: "securepassword",
          password_confirmation: "securepassword"
        }
      }
    end

    user = User.find_by(email_address: "newuser@example.com")
    assert user.user?
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create assigns user role regardless of params" do
    post signup_path, params: {
      user: {
        name: "Sneaky User",
        email_address: "sneaky@example.com",
        password: "securepassword",
        password_confirmation: "securepassword",
        role: "site_admin"
      }
    }

    user = User.find_by(email_address: "sneaky@example.com")
    assert user.user?
    assert_not user.site_admin?
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          name: "",
          email_address: "newuser@example.com",
          password: "securepassword",
          password_confirmation: "securepassword"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with mismatched passwords re-renders form" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          name: "New User",
          email_address: "newuser@example.com",
          password: "securepassword",
          password_confirmation: "differentpassword"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with duplicate email re-renders form" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          name: "Duplicate User",
          email_address: users(:regular_user).email_address,
          password: "securepassword",
          password_confirmation: "securepassword"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "sign in page links to sign up" do
    get new_session_path
    assert_select "a[href=?]", new_signup_path, text: "Sign up"
  end

  test "sign up page links to sign in" do
    get new_signup_path
    assert_select "a[href=?]", new_session_path, text: "Sign in"
  end
end
