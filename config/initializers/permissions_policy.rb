# Define an application-wide permissions policy (formerly Feature-Policy).
# Restricts browser features that are not needed by this application.

Rails.application.config.permissions_policy do |policy|
  policy.camera      :none
  policy.gyroscope   :none
  policy.magnetometer :none
  policy.microphone  :none
  policy.usb         :none
  policy.fullscreen  :self
  policy.payment     :none
  policy.geolocation :none
end
