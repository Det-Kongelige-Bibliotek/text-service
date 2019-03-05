# -*- coding: utf-8 -*-
module ApplicationHelper
  require 'socket'
  require 'nokogiri'

  def get_text_capabilities arg
    parsed_data = Nokogiri::HTML.parse(arg)
    h = Hash.new
    tags = parsed_data.xpath("//a")
    tags.each do |tag|
      h[tag.text] = tag[:href]
    end
    h
  end

  def get_text_capabilities_type arg
    text_capabilities_type = 'Hovedtekst'
    text_capabilities = get_text_capabilities (arg[:capabilities_ssi])
    unless text_capabilities.length == 0
      text_capabilities.each do |key, value|
        if value.include? arg.id
          text_capabilities_type = key
        end
      end
    end
    text_capabilities_type
  end

  def get_period_name args
    res = args
    repository = blacklight_config.repository_class.new(blacklight_config)  
    doc = repository.find(args)
    if doc['response']['docs'].first['work_title_tesim'].present?
      res=doc['response']['docs'].first['work_title_tesim'].join(' ')
    end
    res
  end

  def get_genre_name args
    name = args
    case name
      when "poetry"
      name = "Poesi"
      when "prose"
      name = "Prosa"
      when "play"
      name = "Skuespil"
    end
  end

  def has_only_collection_facet?
    !params[:f].blank? && params[:f].as_json.length == 1 && params[:f]["subcollection_ssi"].present?
  end

  def is_collection_home_page?
    params[:q].blank? && params[:search_field] == 'Alt' && params[:match] == 'one' && has_only_collection_facet?
  end

  def get_collection_home_url args
    collection = args
    case collection
    when "all"
      url = '/text?match=one&q=&match=one&search_field=Alt'
    when "sks"
      url = '/sks'
    when "holberg"
      url = '/lhv'
    when "pmm"
      url = '/pmm'
    when "adl"
      url = '/adl'
    when "grundtvig"
      url = '/gv'
    when "tfs"
      url = '/tfs'
    else
      url = "#"
    end
    url
  end

  def get_collection_name args
     name = args
     case name
       when "sks"
         name = "Søren Kierkegaards Skrifter"
       when "holberg"
         name = "Ludvig Holbergs Skrifter"
       when "pmm"
         name = "Poul Martin Møllers Skrifter"
       when "adl"
         name = "Arkiv for Dansk Litteratur"
       when "grundtvig"
         name = "Grundtvigs Værker"
       when "tfs"
         name = "Trykkefrihedens Skrifter"
     end
     name
  end

  def show_volume args
    id = args[:document]['volume_id_ssi']
    return unless id.present?
    udgave = construct_citation(args)+"."
    link_to udgave.html_safe, solr_document_path(id)
  end

  def construct_citation args
    label = []
    author = ""

    if args[:document]['author_name_ssi'].present?
      author = args[:document]['author_name_ssi'] + ": " if args[:document]['author_name_ssi'].present?
    end
    title = ""

    if args[:document]['volume_title_tesim'].present?
      title = content_tag(:em, args[:document]['volume_title_tesim'].try(:first).to_s)
    end
    # Add author and value as one string so they don't get separated by comma

    if args[:omit_author]
      label << title
    else
      label << author + title
    end

    label << "udg. af #{args[:document]['editor_ssi']}"         if args[:document]['editor_ssi'].present?
    label << "#{args[:document]['publisher_tesim'].join(', ')}" if args[:document]['publisher_tesim'].present?
    label << "#{args[:document]['date_published_ssi']}"         if args[:document]['date_published_ssi'].present?
    # Remove empty string from the array
    label = label.reject { |c| c.empty? }
    return label.join(', ')  
  end

  def citation args
    args[:document] = @document
    # Construct the first part and add the anvendt udgave and the page number
    if args[:document]['is_monograph_ssi']=='yes'
      is_monograph = true
      args[:omit_author] = true
    else
      is_monograph = false
      args[:omit_author] = false
    end 

    #
    # In retrospect one could easily say that there are far too many title fields in the text service
    # And still, we don't have sub-titles, transcribed titles, uniform titles etc.
    #
    tit = args[:document]['work_title_ssi'].present? ? args[:document]['work_title_ssi'].strip :  args[:document]['volume_title_tesim'].first.strip

    cite = ""
    cite += args[:document]['author_name_ssi'] + ": " if(args[:document]['author_name_ssi'].present?  && args[:document][:id] != args[:document]['volume_id_ssi'])
    cite += "”" + tit + "”"
    
    # I know this looks wierd, but it seems we need the ", i " for
    # both anthologies and monographs, but I want to keep it for the
    # time being.

    if(!is_monograph && args[:document]['work_title_ssi'].present? && args[:document][:id] != args[:document]['volume_id_ssi'])
      cite += ", i "
    else
      cite += ", i " 
    end

    cite += construct_citation(args)
    cite += ", s. <span id='pageNumber'>"+args[:document]['page_ssi']+"</span>" if args[:document]['page_ssi'].present?
    cite += ". "
    # Add the URL and the date in the string
    cite += 'Onlineudgave fra ' +  get_collection_name(args[:document]['subcollection_ssi']) + ': ' + request.original_url + "<span id='hashTagInURI'></span>"
    # Add the translated current date
    cite += " (tilgået " + I18n.l(Time.now, format: "%d. %B %Y") +")"
  end

  def author_link args
    ids = args[:value]
    logger.debug "Creating author_link #{args[:document]['author_name_tesim'].to_s}"
    if (ids.is_a? Array) && (ids.size > 1) # we have more than one author
      repository = blacklight_config.repository_class.new(blacklight_config)
      ids.map!{|id| link_to get_author_name(repository,id), solr_document_path(id)}
      result=ids.to_sentence(:last_word_connector => ' og ')
    else
      if ids.is_a? Array
        author_id = ids.first
      else
        author_id = ids
      end
      author_name = args[:document]['author_name_tesim'].first if args[:document]['author_name_tesim'].present?
      author_name ||= "Intet Navn"
      result = link_to author_name, solr_document_path(author_id)
    end
    logger.debug "result is #{result}"
    result
  end

  def translate_model_names(name)
    I18n.t("general.models.#{name}")
  end

  # Generic method to create glyphicon icons
  # supply only the last component of the icon name
  # e.g. 'off', 'cog' etc
  def bootstrap_glyphicon(icon, classes = '')
    content_tag(:span, nil, class: "glyphicon glyphicon-#{icon} #{classes}").html_safe
  end

  def get_author_image(id)
    "authors/#{id.gsub('adl-authors-','').gsub('-root','')}.jpg"
  end

  private

  def get_author_name repository, id
    begin
      solr_docs = repository.find(id).documents
      if solr_docs.size > 0
        solr_docs.first['work_title_tesim'].join
      else
        id
      end
    rescue Exception => e
      id
    end
  end

  def get_host_name
    hostname=Socket.gethostname
  end
end
