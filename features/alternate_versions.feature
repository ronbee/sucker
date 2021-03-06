Feature: Alternate versions
  As an API consumer  
  I want to look up alternate versions of an item  
  Because that has some business value.

  Background:
    Given the following:
      """
      @worker = Sucker.new(
        :key    => amazon_key,
        :secret => amazon_secret,
        :locale => :us)
      """

  Scenario: Alternate versions response group
    Given the following:
      """
      @worker << {
        :operation         => 'ItemLookup',
        :id_type           => 'ASIN',
        :item_id           => '0679753354',
        :response_group    => 'AlternateVersions' }
      """
    When I tape:
      """
      @response = @worker.get
      """
    Then I expect:
      """
      @response['AlternateVersion'].size.should be > 1
      """
