module ApplicationHelper
  def sidebar_link(label, path, icon_name)
    active = current_sidebar_item == icon_name
    base_classes = "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors"
    active_classes = active ? "bg-blue-50 text-blue-700" : "text-gray-600 hover:bg-gray-100 hover:text-gray-900"

    link_to path, class: "#{base_classes} #{active_classes}" do
      concat(sidebar_icon(icon_name, active))
      concat(content_tag(:span, label, class: "hidden whitespace-nowrap", data: { sidebar_target: "label" }))
    end
  end

  def current_sidebar_item
    @current_sidebar_item || case controller_name
                             when "dashboard" then "dashboard"
                             when "meetings" then "meetings"
                             when "council_members" then "council_members"
                             when "tags" then "topics"
                             when "search" then "search"
                             end
  end

  def sidebar_icon(name, active = false)
    color = active ? "text-blue-600" : "text-gray-400"
    case name
    when "dashboard"
      content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5 shrink-0 #{color}", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", "stroke-width": "1.5") do
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", d: "M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z")
      end
    when "meetings"
      content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5 shrink-0 #{color}", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", "stroke-width": "1.5") do
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", d: "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5")
      end
    when "council_members"
      content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5 shrink-0 #{color}", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", "stroke-width": "1.5") do
        concat(tag.path("stroke-linecap": "round", "stroke-linejoin": "round", d: "M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"))
      end
    when "topics"
      content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5 shrink-0 #{color}", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", "stroke-width": "1.5") do
        concat(tag.path("stroke-linecap": "round", "stroke-linejoin": "round", d: "M9.568 3H5.25A2.25 2.25 0 003 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 005.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 009.568 3z"))
        concat(tag.path("stroke-linecap": "round", "stroke-linejoin": "round", d: "M6 6h.008v.008H6V6z"))
      end
    when "search"
      content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5 shrink-0 #{color}", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", "stroke-width": "1.5") do
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", d: "M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z")
      end
    end
  end
end
