module DateHelper
    
  def show_as_date(datetime)
    datetime.blank? ? "" : date_object(datetime).strftime('%B %e, %Y')  
  end

  def show_as_datetime(datetime)
    datetime.blank? ? "" : date_object(datetime).strftime('%B %e, %Y')  
  end

  def date_object(input)
    if input.class == String
      begin
        return Date.parse(input)
      rescue
        return nil
      end
    end
    return input
  end
  
end