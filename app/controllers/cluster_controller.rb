class ClusterController < ApplicationController
  def show
    begin
      @error = false
      cluster = Conformer.find_by_pdb_id([params[:codnasq_id]]) || Cluster.find(cluster_id)
      if cluster.class.to_s == 'Conformer'
        cluster = Cluster.find_by_codnasq_id(cluster.cluster_id)    
      end     
      conformers_cluster = Conformer.where(cluster: cluster)
      render 'cluster/show',
        locals: {
          cluster: cluster,
          conformers: conformers_cluster,
          max_pair: cluster.max_rmsd_pair,
          query: cluster.max_rmsd_pair.query,
          target: cluster.max_rmsd_pair.target,
        }
    rescue => e
      # Redirect to not-found page
      @error = true
    end
  end

  def search
    query = params[:query].downcase

    case params[:criteria]
    when 'Name'
      @conformers = Conformer.where('lower(name) LIKE ?', "%#{query}%").page(params[:page])
    when 'Organism'
      @conformers = Conformer.where('lower(organism) LIKE ?', "%#{query}%").page(params[:page])
    when "Cluster (by PDB)"
      redirect_to cluster_show_path(query)
    else
      @conformers = Conformer.search_in_all_fields(query).page(params[:page])
    end
  end

  private

  def cluster_id
    Float(params[:codnasq_id], exception: false)
  end
end
