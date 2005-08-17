# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base

  def get_ymd
    if @ymd
      ymd = @ymd
    elsif @params['ymd2']
      ymd = convert_ymd(@params['ymd2']) 
    elsif (@params["year"] and @params["month"] and @params["day"])
      ymd = convert_ymd("#{@params["year"]}-#{@params["month"]}-#{@params["day"]}")
    elsif (@params["year"] and @params["month"])
      ymd = convert_ymd("#{@params["year"]}-#{@params["month"]}-01")
    end
    @ymd = ymd

    if ymd =~ /(\d\d\d\d)-(\d\d)-(\d\d)/
      t2 = Time.local($1,$2,$3)
      @ymd10a = t2 + 86400 * 10 - 1
#      @ymd1a = t2 + 86400 - 1
      @ymd1a = t2.tomorrow
      @ymd31a = t2.next_month
    end
  end

  def convert_ymd(ymdhash)
    if ymdhash =~ /\d\d\d\d-\d\d-\d\d/
      return ymdhash 
    elsif ymdhash =~ /(\d\d\d\d)-(\d\d?)-(\d\d?)/
      y = $1
      m = $2
      d = $3
    elsif ymdhash =~ /(\d\d\d\d)(\d\d)(\d\d)/
      y = $1
      m = $2
      d = $3
    else
      y = ymdhash['created_on(1i)'] 
      m = ymdhash['created_on(2i)']
      d = ymdhash['created_on(3i)']
    end

    ymd = "#{y}-"
    if m =~ /\d\d/
      ymd += "#{m}-"
    elsif m.to_i < 10
      ymd += "0#{m}-"
    else
      ymd += "#{m}-"
    end
    if d =~ /^0\d$/
      ymd += d
    elsif d.to_i < 10
      ymd += "0#{d}"
    else
      ymd += "#{d}"
    end
    return ymd
  end

end
