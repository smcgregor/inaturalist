module Shared::WikipediaModule
  def wikipedia
    @title ||= params[:id]
    coder = HTMLEntities.new
    w = WikipediaService.new
    @decoded = ""
    begin
      query_results = w.query(
        :titles => @title, 
        :redirects => '', 
        :prop => 'revisions', 
        :rvprop => 'content')
      unless query_results.at('page')['missing']
        raw = query_results.at('page')
        parsed = w.parse(:page => raw['title']).at('text').inner_text
        @decoded = coder.decode(parsed)
        @decoded.gsub!('href="/', 'href="http://en.wikipedia.org/')
        @decoded.gsub!('src="/', 'src="http://en.wikipedia.org/')
        filter_wikipedia_content
      end
    rescue Timeout::Error => e
      logger.info "[INFO] Wikipedia API call failed: #{e.message}"
    end
    
    respond_to do |format|
      format.html do
        if @decoded.empty?
          render(:text => "Wikipedia doesn't have a page for #{@title}", 
            :status => 404)
        else
          render(:text => @decoded)
        end
      end
    end
  end
  
  private
  
  # Override and filter the contents of @decoded if you need to
  def filter_wikipedia_content
  end
end