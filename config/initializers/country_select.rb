# https://github.com/countries/country_select
  
# Return an array to customize <option> text, `value` and other HTML attributes
CountrySelect::FORMATS[:with_data_attrs] = lambda do |country|
    ["#{country.alpha2} +#{country.country_code}",
    "#{country.alpha2}"
    ]
end