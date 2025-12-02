module ApplicationHelper
  def provider_name(provider)
    case provider
    when "google_oauth2" then "Google"
    when "twitter2" then "Twitter"
    when "facebook" then "Facebook"
    else provider.titleize
    end
  end

  def provider_button_class(provider)
    base = "w-full flex items-center justify-center gap-3 px-6 py-3 rounded-lg transition duration-200 font-medium"
    case provider
    when "google_oauth2"
      "#{base} bg-white border border-gray-300 text-gray-700 hover:bg-gray-50"
    when "twitter2"
      "#{base} bg-black text-white hover:bg-gray-800"
    when "facebook"
      "#{base} bg-[#1877F2] text-white hover:bg-[#166FE5]"
    else
      "#{base} bg-gray-200 text-gray-800 hover:bg-gray-300"
    end
  end
end
