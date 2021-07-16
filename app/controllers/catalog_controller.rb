# -*- coding: utf-8 -*-
# frozen_string_literal: true
require 'oai_provider'

class CatalogController < ApplicationController

  include Blacklight::Catalog
  include BlacklightRangeLimit::ControllerOverride

  
  #get the list of all authors in a period when we are showing af period
  before_action :get_authors_in_period, only: [:show], if: :showing_period?

  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
        :qt => 'search',
        :rows => 10,
        :hl => 'true',
        :'hl.snippets' => '3',
        :'hl.simple.pre' => '<em class="highlight" >',
        :'hl.simple.post' => '</em>'
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'
    #config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    config.index.title_field = 'work_title_tesim'
    config.index.display_type_field = 'cat_ssi'

    # solr field configuration for document/show views
    #config.show.title_field = 'title_display'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar

    config.add_facet_field 'author_name_ssim', :label => 'Forfatter', :single => true, :limit => 10, :collapse => false
    config.add_facet_field 'person_name_ssim', :label => 'Anden person', :single => true, :limit => 10, :collapse => true
    config.add_facet_field 'other_location_ssim', :label => 'Sted', :single => true, :limit => 10, :collapse => true
    config.add_facet_field 'contains_ssi', :label => 'Indeholder mest', :single => true, :limit => 10, :collapse => false, helper_method: :get_genre_name
#    config.add_facet_field 'perioid_ssi', :label => 'Periode', :single => true, :limit => 10, :collapse => true, helper_method: :get_period_name
    config.add_facet_field 'subcollection_ssi', :label => 'Samling', :single => true, :limit => 10, :collapse => false, helper_method: :get_collection_name
    config.add_facet_field 'text_type_ssi', :label => 'Tekstkategori', :single => true, :limit => 10, :collapse => false
    config.add_facet_field 'textclass_genre_ssim', :label => 'Tekstklassifikation', :single => true, :limit => 10, :collapse => true
    config.add_facet_field 'textclass_keywords_ssim', :label => 'Emneord', :single => true, :limit => 10, :collapse => true
    config.add_facet_field 'bible_ref_ssim', :label => 'Bibelsted', :single => true, :limit => 10, :collapse => true
    config.add_facet_field 'year_itsi', label: 'Årstal', range: {
                         num_segments: 10,
                         assumed_boundaries: [1500, Time.now.year + 2],
                         segments: true,
                         maxlength: 4
                       }

#    config.add_facet_field 'pub_date', label: 'Publication Year',
#                           range: {
#                             num_segments: 10,
#                             assumed_boundaries: [1900, Time.now.year + 2],
#                             segments: true,
#                             maxlength: 4
#                           }

    
    
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'author_id_ssi', :label => 'Forfatter', helper_method: :author_link, short_form: true, itemprop: :author

    config.add_index_field 'subcollection_ssi', :label => 'Samling', :single => true,  short_form: true, helper_method: :get_collection

    #config.add_index_field 'person_id_ssi', :label => 'Person', helper_method: :person_link, short_form: true, itemprop: :person

    
    ## if we have no author_id_ssi (link to author portrait, just show the author name)
    config.add_index_field 'author_name_tesim', :label => 'Forfatter',  short_form: true, itemprop: :author, unless: proc {|_context, _field_config, doc| doc['author_id_ssi'].present?}
    
    #    config.add_index_field 'person_name_tesim', :label => 'Person',  short_form: true, itemprop: :person, unless: proc {|_context, _field_config, doc| doc['person_id_ssi'].present?}
    
    config.add_index_field 'year_itsi', :label => 'Udgivelsesdato'

    config.add_index_field 'volume_title_tesim', :label => 'Anvendt udgave', helper_method: :show_volume, short_form: true, itemprop: :isPartOf, unless: proc { |_context, _field_config, doc | doc.id == doc['volume_id_ssi'] }
    
    #config.add_index_field 'editor_ssi', :label => 'Redaktør', itemprop: :editor


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display


    # Work show fields
    config.add_show_field 'author_id_ssi', :label => 'Forfatter', helper_method: :author_link, itemprop: :author
    config.add_show_field 'person_id_ssi', :label => 'Person', helper_method: :person_link, itemprop: :person
    config.add_show_field 'volume_title_tesim', :label => 'Anvendt udgave', helper_method: :show_volume, itemprop: :isPartOf
    #
    # , unless: proc { |_context, _field_config, doc | doc.id == doc['volume_id_ssi'] }
    #
    config.add_show_field 'work_title_tesim', :label => 'Citér', helper_method: :citation # , unless: proc { |_context, _field_config, doc | doc.id == doc['volume_id_ssi'] }
    config.add_show_field 'publisher_tesim', :label => 'Udgiver', unless: proc { |_context, _field_config, doc | doc['cat_ssi'] == 'volume' }
    config.add_show_field 'place_published_tesim', :label => 'Udgivelsessted'
    config.add_show_field 'date_published_ssi', :label => 'Udgivelsesdato'

    config.show.document_actions.citation.if = :render_citation_action?



    # we do not want to start a new search_session for 'leaf' searches
    # to avoid messing up previous and next links
    def start_new_search_session?
      action_name == "index" && params['search_field'] != 'leaf'
    end

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('Alt',label: I18n.t('general.config.search.all_filters')) do |field|
      field.solr_parameters = {
          :fq => ['type_ssi:work'],
          :qf => 'author_name_tesim^5 work_title_tesim^5 text_tsim',
          :pf => 'text_tsim'
      }
      field.solr_local_parameters = {
      }
    end


    config.add_search_field('author_title',label: I18n.t('general.config.search.author_title')) do |field|
      field.solr_parameters = {
        :fq => ['type_ssi:work'],
        :qf => 'author_name_tesim work_title_tesim',
        :pf => 'work_title_tesim'
      }
      field.solr_local_parameters = {
      }
    end


#    config.add_search_field('title', label: I18n.t('general.config.search.title')) do |field|
#      # solr_parameters hash are sent to Solr as ordinary url query params.
#      field.solr_parameters = {
#          :fq => ['cat_ssi:work'],
#          :qf => 'work_title_tesim',
#          :pf => 'work_title_tesim',
#      }
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
 #     field.solr_local_parameters = {
#      }
#    end

 #   config.add_search_field('author', label: I18n.t('general.config.search.author')) do |field|
#      field.solr_parameters = {
#          :fq => ['cat_ssi:work'],
#          :qf => 'author_name_tesim',
#          :pf => 'author_name_tesim'
#      }
#      field.solr_local_parameters = {
#      }
#    end


    config.add_search_field('person', label: I18n.t('general.config.search.person')) do |field|
      field.solr_parameters = {
        :fq => ['type_ssi:work'],
        :qf => 'person_name_tesim',
        :pf => 'person_name_tesim'
      }
      field.solr_local_parameters = {
      }
    end
  
    config.add_search_field('prose', label: I18n.t('general.config.search.prose')) do |field|
      field.solr_parameters = {
        :fq => ['type_ssi:work'],
        :qf => 'prose_extract_tesim',
        :pf => 'prose_extract_tesim'
      }
      field.solr_local_parameters = {
      }
    end

    config.add_search_field('verse', label: I18n.t('general.config.search.verse')) do |field|
      field.solr_parameters = {
        :fq => ['type_ssi:work'],        
        :qf => 'verse_extract_tesim',
        :pf => 'verse_extract_tesim'
      }
      field.solr_local_parameters = {
      }
    end

    config.add_search_field('play', label: I18n.t('general.config.search.play')) do |field|
      field.solr_parameters = {
        :fq => ['type_ssi:work'],                
        :qf => 'performance_extract_tesim',
        :pf => 'performance_extract_tesim'
      }
      field.solr_local_parameters = {
      }
    end


#
# We can leave some sediment here
#
#    config.add_search_field('phrase',label: I18n.t('general.config.search.phrase')) do |field|
#      field.solr_parameters = {
#          :fq => ['cat_ssi:work'],
#          :qf => 'text_tsim',
#          :pf => 'text_tsim',
#          :ps => 0,
#          :qs => 0,
#      }
#      field.solr_local_parameters = {
#      }
#    end

    config.add_search_field('leaf') do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
          :fq => 'type_ssi:leaf',
          :qf => 'text_tsim',
          :pf => 'text_tsim',
          :hl => 'true',
      }
      field.solr_local_parameters = {
      }
    end



    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc', :label => (I18n.t'general.config.sort.relevance')
    config.add_sort_field 'author_name_ssi asc', :label => (I18n.t'general.config.sort.author')
    config.add_sort_field 'sort_title_ssi asc', :label => (I18n.t'general.config.sort.title_asc')
    config.add_sort_field 'sort_title_ssi desc', :label => (I18n.t'general.config.sort.title_desc')
    config.add_sort_field 'year_itsi asc', :label => (I18n.t'general.config.sort.year_asc')
    config.add_sort_field 'year_itsi desc', :label => (I18n.t'general.config.sort.year_desc')
    config.spell_max = 5



    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'

   
    oai_solr = []
    config.oai_config = {
        :default_solr_params => {
            :fq => "type_ssi:work"
        },
        :timestamp_field => 'timestamp',
        :limit => 20,
        :sets => [
          {
            :name => 'ADL',
            :desc => 'Archive for Danish Literature',
            :spec => 'kb.adl',
            :solr_params => {
              :fq => "subcollection_ssi:adl"
            }
#            :solr_params => {},
          },
          {
            :name => 'TFS',
            :desc => 'Trykkefrihedens Skrifter',
            :spec => 'kb.tfs',
            :solr_params => {
              :fq => "subcollection_ssi:tfs"
            }
#            :solr_params => {}
          }
        ]
    }
 end



 # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email_action documents
    report = params[:report].nil? ? "" : params[:report]
    report +=  I18n.t('general.config.email.text.from', value: current_user.email) + "\n" unless current_user.nil?
    mail = RecordMailer.email_record(documents, {:to => params[:to], :message => report+"\n\n"+params[:message]}, url_options)
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end


  def feedback
    @response, @document = search_service.fetch URI.unescape(params[:id])
    @report = ""
    @report +=  I18n.t('general.config.email.text.from', value: current_user.email) + "\n" unless current_user.nil?
    @report +=  I18n.t('general.config.email.text.url', url: @document['url_ssi']) + "\n" unless @document['url_ssi'].blank?
    @report += I18n.t('general.config.email.text.author', value: @document['author_name'].first) + "\n" unless @document['author_name'].blank?
    @report += I18n.t('general.config.email.text.title', value: @document['work_title_tesim'].first.strip)+ "\n" unless @document['work_title_tesim'].blank?
    render layout: nil
  end

  def is_text_search?
    ['authors','periods'].exclude? action_name
  end

  def has_search_parameters?
    super || !is_text_search?
  end

  def render_email_action?
    current_user.present? && self.class == CatalogController
  end

  def render_feedback_action?
    current_user.present? && self.class == CatalogController
  end

  def render_sms_action?
    false
  end

  def render_citation_action?
    self.class == CatalogController
  end

  
 # Overwriting this method to enable pdf generation using WickedPDF
 # Unfortunately the additional_export_formats method was quite difficult
 # to use for this use case.
  def show
    repository = blacklight_config.repository_class.new(blacklight_config)
    @document = repository.find(params[:id]).documents.first
#    deprecated_response, @document = search_service.fetch(params[:id])
 #   @response = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(deprecated_response, 'The @response instance variable is deprecated; use @document.response instead.')

    respond_to do |format|
      format.html { @search_context = setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      format.pdf {send_pdf(@document,'text')}
      additional_export_formats(@document, format)
    end
  end

 # common method for rendering pdfs based on wicked_pdf
 # cache files in the public folder based on their id
 # perhaps using the Solr document modified field
  def send_pdf(document, type)
    repository = blacklight_config.repository_class.new(blacklight_config)
    name = document['work_title_tesim'].first.strip rescue document.id
    edition = ""
    if document['cat_ssi'] != 'author' and document['cat_ssi'] != 'period' 
    edition = '<dt>Anvendt udgave:</dt><dd>' + document['volume_title_tesim'].first + '</dd>'
    end
    author_portrait = ''
    if document['cat_ssi'] == 'author'
      author_portrait = 'Forfatterportræt af '
    end
    auth_name = ""
    if document.has_key?('author_name_ssi')
          auth_name = '<dt>Forfatter:</dt><dd>' + document['author_name_ssi'] + '</dd>' 
    end
    tit = ''
    begin
      tit = document['work_title_tesim'].first
    rescue
      tit = "Udrag fra " + helpers.get_parent_work(document.id)['work_title_tesim'].first
    end

    # image has to be local to show up in pdf
    pd = ""
    if document['subcollection_ssi'] == "tfs"
      pd = '<dt>Ophavsret</dt>' +
      '<dd>Materialet er fri af ophavsret. Du kan kopiere, ændre, distribuere eller fremføre værket,
      også til kommercielle formål, uden at bede om tilladelse.</dd>' +
      '<dd><a rel="license" href="https://creativecommons.org/publicdomain/mark/1.0/deed.da">Læs Public Domain-erklæringen</a>.</dd>'
    else
      pd = '<dt>Ophavsret</dt>' +
      '<dd>Materialet er dedikeret til public domain. Du kan kopiere, ændre, distribuere og fremføre 	værket, også til kommercielle formål, uden at bede om tilladelse. Husk dog altid at kreditere ophavsmanden.</dd>' +
      '<dd><a rel="license" href="https://creativecommons.org/publicdomain/zero/1.0/deed.da">Læs CC0-erklæringen</a>.</dd>'
    end
    
    render pdf: name,
           footer: {right: '[page] af [topage] sider'},
           header: {html: {template: 'shared/pdf_header.pdf.erb'},
                    spacing: 5},
           margin: {top: 15, # default 10 (mm)
                    bottom: 15},
           encoding: 'utf8', # needed here to encode danish characters
           cover: '<style>dl > dt {float: left; width: 160px; clear: left; text-align: right; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;} dl > dd{margin-top: 0; margin-bottom: 20px; margin-left: 180px;}</style>'+
               'Fra Det Kgl. Biblioteks tekstportal (tekster.kb.dk) <br /> <hr> <br /><br />' +
               '<dl>'+
               auth_name +
               '<dt>Titel:</dt><dd>' + author_portrait + tit + '</dd>' +
               '<dt>Citation:</dt><dd style="">' + helpers.citation(@document.instance_values)  + '</dd>' +
               edition + pd
               '</dl>'
  end

   def facsimile
    @response, @document = search_service.fetch(params[:id])
    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.pdf { send_pdf(@document, 'image') }
    end
  end

  # actions for generating the list of authorportraits and period descriptions
  def periods
    (@response,@deprecated_document_list) = search_service.search_results do |builder|
      builder = blacklight_config.default_solr_params.merge({rows: 10000, fq:['cat_ssi:period','type_ssi:work'], sort: 'sort_title_ssi asc'})
    end
    render "index"
  end

  def authors
    (@response,@deprecated_document_list) = search_service.search_results do |builder|
      builder = blacklight_config.default_solr_params.merge({rows: 10000, fq:['cat_ssi:author','type_ssi:work'], sort: 'sort_title_ssi asc'})
    end
    render "index"
  end

  def collection
    id = params['id']
    case id
    when "gv"
      id = "gv"
    when "lhv"
      id = "lhv"
    end
    redirect_to  action: 'index', f: {subcollection_ssi: ["#{id}"]}, editorial: 'no',  match: 'one', search_field: 'Alt'
  end

  def oai
    options = params.delete_if { |k,v| %w{controller action}.include?(k) }
    render xml: oai_provider.process_request(options)
  end

  def oai_provider
    @oai_provider ||= OaiProvider.new(search_service,blacklight_config.oai_config)
  end

  private

  def showing_period?
    params['id'].present? && params['id'].starts_with?('adl-periods')
  end

  def get_authors_in_period
    (@auth_resp, @auth_docs) = search_service.search_results do |builder|
      if respond_to? (:blacklight_config)
        builder = blacklight_config.default_solr_params.merge({rows: 10000, fq:['cat_ssi:author',"perioid_ssi:#{params[:id]}"]})
      end
    end
  end

  # method to be used in the views, that checks if the selected search field is fritekst
  def search_field_fritekst?
    ['Alt','phrase','prose','verse','play'].include? params['search_field']
  end
  helper_method :search_field_fritekst?

end
