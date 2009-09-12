class WikipediaService < MetaService
  def initialize
    super
    @endpoint = 'http://www.sdwatersheds.org/wiki/api.php?'
    @method_param = 'action'
    @default_params = { :format => 'xml' }
  end
end