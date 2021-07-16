# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder


  ##
  # @example Adding a new step to the processor chain
  #   self.default_processor_chain += [:add_custom_data_to_query]
  #
  #   def add_custom_data_to_query(solr_parameters)
  #     solr_parameters[:custom] = blacklight_params[:user_value]
  #   end

  self.default_processor_chain +=
    [:restrict_to_author_id,
     :add_work_id,
     :add_timestamp_interval,
     :search_editorial_as_well,
     :more_search_params]

  def search_editorial_as_well  solr_params
    if blacklight_params[:editorial].present? && blacklight_params[:editorial] == 'yes'
      solr_params[:fq] << "is_editorial_ssi:yes"
    else
      if blacklight_params[:editorial].present? && blacklight_params[:editorial] == 'no'
        solr_params[:fq] << "is_editorial_ssi:no"
      else
        solr_params[:fq] << "is_editorial_ssi:*"
      end
    end
  end
  
  def add_work_id solr_params
    if blacklight_params[:search_field] == 'leaf' && blacklight_params[:workid].present?
      #      solr_params[:fq] ||= []
      solr_params[:fq] = []
      solr_params[:fl] = [:id,:text_tsim,:bible_ref_ssim,:volume_id_ssi,:page_ssi,:position_isi,:xmlid_ssi,:is_editorial_ssi]
      workid    = blacklight_params[:workid]
      # editorial = blacklight_params[:editorial]
      # workid = "#{workid}*" unless workid.include? '*'
      # sorting in document order
      solr_params[:facet] = false
      solr_params['facet.field'] = []
      solr_params['facet.query'] = []
      solr_params[:sort] = []
      solr_params[:sort] << 'position_isi asc'
      # part of search
      solr_params[:fq] << "type_ssi:leaf"
      solr_params[:fq] << "part_of_ssim:#{workid}"

      # solr_params[:fq] << "is_editorial_ssi:*"

    end
  end

  def restrict_to_author_id solr_params
    if (blacklight_params[:authorid].present?)
      solr_params[:fq] ||= []
      solr_params[:fq] << "author_id_ssi:#{blacklight_params[:authorid]}"
      solr_params[:fq] << "type_ssi:work"
      # should this one be type_ssi:work ???
    end
  end

  def part_of_volume_search solr_params
    solr_params[:fq] = []
    solr_params[:fq] << "type_ssi:leaf"
    solr_params[:fq] << "volume_id_ssi:#{blacklight_params[:volumeid]}"
    solr_params[:rows] = 10000

  end

  def build_authors_in_period_search solr_params = {}
    solr_params[:fq] = []
    solr_params[:fq] << 'cat_ssi:author'
    solr_params[:fq] << "perioid_ssi:#{blacklight_params[:perioid]}"
    solr_params[:sort] = []
    solr_params[:sort] << 'work_title_ssi asc'
    solr_params[:rows] = 10000
  end

  def add_timestamp_interval solr_params
    timeinterval_string = '['+ (blacklight_params[:from].present? ? blacklight_params[:from] : '*')
    timeinterval_string += ' TO '
    timeinterval_string += (blacklight_params[:until].present? ? blacklight_params[:until] : '*') +']'
    solr_params[:fq] ||= []
    solr_params[:fq] << "timestamp:#{timeinterval_string}"
  end

  def more_search_params solr_params
    # this is not the optimal way of doing phrase search, but i have not find the right solr params
    if blacklight_params['match'] == 'phrase'
      # We do have problems with string searching when the query contains quotation marks
      # because we want to add them ourselves
      solr_q_string = ''
      if solr_params['q']
        solr_q_string = solr_params['q']
      end
      solr_params['q'] =  solr_q_string.gsub(/\"/,'')
      solr_params['q'] = "\"#{ solr_q_string}\""
      solr_params['qs'] = 0
    end
    if blacklight_params['match'] == 'all'
      if blacklight_params[:search_field] == 'leaf'
        solr_params[:mm] = 1
      else
        solr_params[:mm] = '100%'
      end
    end
    if blacklight_params['match'] == 'one' || !blacklight_params['match'].present?
      solr_params[:mm] = 1
    end
    solr_params
  end
end
