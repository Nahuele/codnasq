require 'csv'
require 'open-uri'
require_relative './profiler'
require_relative './csv_parse'

LOCAL_MINI_DB = "#{Rails.root}/db/dbqmini.csv".freeze
EXTERNAL_COMPLETE_DB = 'http://ufq.unq.edu.ar/codnasq/dbqcomplete.csv'.freeze
EXTERNAL_MINI_DB = 'http://ufq.unq.edu.ar/codnasq/dbqmini.csv'.freeze

external_csv_to_import = EXTERNAL_COMPLETE_DB


puts("Amount of Cluster: #{Cluster.count}")
puts("Amount of Conformer: #{Conformer.count}")
puts("Amount of ConformerPair: #{ConformerPair.count}")

profile do
  puts("Opening: #{external_csv_to_import}")

  URI.open(external_csv_to_import) do |file|
    csv_headers = file.first

    file.lazy.each_slice(2000) do |file_lines|
      clusters = []
      conformers = []
      pairs = []

      parse_csv_rows(csv_headers, file_lines).each do |row|
        clusters << parse_cluster(row)
        pairs << parse_pair(row)
        conformers << parse_query(row)
        conformers << parse_target(row)
      end

      clusters_to_save = clusters.uniq { |cluster| cluster[:codnasq_id] }
      conformers_to_save = conformers.uniq { |conformer| conformer[:pdb_id] }

      puts("About to insert Cluster: #{clusters_to_save.size}, Conformer: #{conformers_to_save.size}, ConformerPair: #{pairs.size}")

      Cluster.insert_all(clusters_to_save)
      Conformer.insert_all(conformers_to_save)
      ConformerPair.insert_all(pairs)
    end
  end
end

puts('Import finished')
puts("Amount of Cluster: #{Cluster.count}")
puts("Amount of Conformer: #{Conformer.count}")
puts("Amount of ConformerPair: #{ConformerPair.count}")

#Dir[File.join(Rails.root, 'db/data_migrations/**/*.rb')].sort.each do |data_migration|
#  load data_migration
#end
