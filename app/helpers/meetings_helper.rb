module MeetingsHelper
  def result_badge_class(result)
    case result
    when "approved", "adopted", "carried"
      "bg-green-100 text-green-800"
    when "defeated"
      "bg-red-100 text-red-800"
    when "withdrawn"
      "bg-gray-100 text-gray-600"
    when "introduced", "tabled"
      "bg-yellow-100 text-yellow-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def vote_badge_class(position)
    case position
    when "aye"
      "bg-green-50 text-green-700"
    when "nay"
      "bg-red-50 text-red-700"
    when "abstain"
      "bg-yellow-50 text-yellow-700"
    when "absent"
      "bg-gray-50 text-gray-500"
    end
  end
end
