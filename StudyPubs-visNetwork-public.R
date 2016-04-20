###############################################################################
# FILE: StudyPubs-visNetwork-public.R
# DESCR: visNetwork force network graph of studies and their publications. 
#        Links back to Virtuoso faceted browswer view (if available) or uses
#        example nodes and edges dataframes when  triple store not avail.
# INPUT:  SPARQL query Virtuoso using rrdf  
#         (OR)
#         node, edges dataframe 
# ENDP : http://localhost:8890/sparql
# REQ  : Virtuoso server running  : virtuoso-t -f virtuoso.ini
#        Data in graph http://localhost:8890/KPUB
# NOTES: 
###############################################################################
library(rrdf)        # SPARQL to triple store
library(dplyr)       # to sort (arrange) dataframe before assiging ID to node
library(stringr)     # str_extract of node$name
library(visNetwork)

# Local Virtuoso instance. 
# Skip to section: DATA FROM EXAMPLE DATAFRAME if no triple store
endpoint = "http://localhost:8890/sparql"

#########
# Nodes #
###############################################################################
# Get the list of unique 1) STUDY names and 2) Publication URIs. These will
# form the nodes in the resulting graph. GROUP (node type) is extracted 
# from the typeURI for publications, set manually for "study" from the nameURI 
# NOTE: KPUB not specified using a prefix in order to get full URI for the obs, 
# instead of kpub:obs1. Possible lmitation of rrdf package?
# ?title will show as the mouseover text. 
query = 'PREFIX prov:  <http://www.w3.org/ns/prov#> 
SELECT DISTINCT ?nameURI ?typeURI ?title
FROM <http://localhost:8890/KPUB>
WHERE{
    { 
        ?kpubURI a <http://www.example.org/kpub/publication> ;
        prov:hadPrimarySource ?nameURI.
        VALUES (?typeURI) {("http://www.example.org/kpub/code/Study")}
        BIND (strafter(str(?nameURI), "kmd/") as ?title)
    }
    UNION
    {
        ?nameURI a <http://www.example.org/kpub/publication> ;
                 a ?typeURI ;
              <http://www.example.org/kpub/hasTarget> ?title . 
        FILTER(regex(?typeURI, "Manus|Abs|Pres|Poster","i"))
    }
}'
nodeList = as.data.frame(sparql.remote(endpoint, query))
# Remove any duplicates before assigning unique ID 
nodes <- nodeList[!duplicated(nodeList$nameURI),]
# Sort by names 
nodes<-arrange(nodes,nameURI)  

# Create the node ID values starting at 0 
id<-0:(nrow(nodes)-1) 

# Add the ID to the dataframe
nodes<-data.frame(id, nodes[])  

# Remove URIs from name, group for display purposes
nodes$name <- str_extract(nodes$nameURI, "\\w+$")
nodes$group <- str_extract(nodes$typeURI, "\\w+$") 

##########
# edges  #
#######################################################################
# source = study nodes
# target = publication nodes
# NOTE: removed use of KPUB prefix in order to get full URI for the obs, 
# instead of kpub:obs1.  Problem with RRDF library?

queryedges = 'PREFIX prov:  <http://www.w3.org/ns/prov#> 
SELECT DISTINCT ?sourceURI ?targetURI ?typeURI
FROM <http://localhost:8890/KPUB>
WHERE{
?targetURI a  <http://www.example.org/kpub/publication> ;
           a ?typeURI ;
           prov:hadPrimarySource ?sourceURI.
FILTER(regex(?typeURI, "Manus|Abs|Pres|Poster","i"))
}'

edgeList = as.data.frame(sparql.remote(endpoint, queryedges))

# Merge ID on SOURCE field
edges <- merge (edgeList, nodes, by.x="sourceURI", by.y="nameURI")
names(edges)[names(edges) == 'id'] <- 'from'
edges <- merge (edges, nodes, by.x="targetURI", by.y="nameURI")

names(edges)[names(edges) == 'id'] <- 'to'

# An Unnecessary tidy... 
nodes<- as.data.frame(nodes[c("id", "name", "nameURI", "title", "group")])

# Keep only FROM and TO this time. In other to graphs you may want
# different relation types between nodes. This graph is always hasPub
edges<-as.data.frame(edges[c("from", "to")])
edges$label <- paste("hasPub") # Every relation is hasPub in this example.
# visNetwork needs the TO end of the relation to set arrow head. 
edges$arrows <- paste("to")  


#------------------------------------------------------------------------------
# DATA FROM EXAMPLE DATAFRAME 
#   Create a small set of data for instances when triple store not available.
#------------------------------------------------------------------------------
nodes <-data.frame(id = 0:4,
    name = c("STUDYA", "obs100", "obs023", "obs079", "obs340"),
    nameURI = c("http://www.example.org/kmd/STUDYA",
              "http://www.example.org/kmd/obs100",
              "http://www.example.org/kmd/obs023",
              "http://www.example.org/kmd/obs079",
              "http://www.example.org/kmd/obs340"),
    group = c("Study", "Abstract", "Manuscript", "Poster", "Presentation"),
    title = c("A description of Study A",
              "Acta Neurologica Scandinavica",
              "Archives of Medical Science",
              "European Congress of Common Diseases",
              "American Academy of Neurology Conference"
              )
    )

edges <- data.frame(from = c(0,0,0,0), to=1:4, label="hasPub", arrows='to')


#------------------------------------------------------------------------------
# selectNode function call forms the HREF value for reference back to the 
#   faceted browser view in Virtuoso. Assumes triple store is running. The HREF 
#   formed will be similar to: 
#          http://localhost:8890/describe/?uri=http://www.example.org/kmd/obs100
#
# Icon codes reference available here: http://fortawesome.github.io/Font-Awesome/icons/
visNetwork(nodes, edges) %>%
    visLegend (width = 0.1)%>%
    visEvents(selectNode = "function(properties) {
        location.href='http://localhost:8890/describe/?uri=' + this.body.data.nodes.get(properties.nodes[0]).nameURI;
    }") %>%
    visEdges(smooth = FALSE, shadow = TRUE) %>%
    visNodes(shadow = TRUE) %>%
    visGroups(groupname="Study", shape = "icon", 
              icon = list(code="f0c0", size=100, color ="blue" )) %>%
    visGroups(groupname="Manuscript", shape = "icon", 
              icon = list(code="f0f6", size=100, color = "red"  )) %>%
    visGroups(groupname="Abstract", shape = "icon", 
              icon = list(code="f03a", size=100, color = "grey")) %>%
    visGroups(groupname="Presentation", shape = "icon", 
              icon = list(code="f1fe", size=100, color = "orange" )) %>%
    visGroups(groupname="Poster", shape = "icon", 
              icon = list(code="f1c4", size=100, color = "green" )) %>%
    visInteraction(dragNodes = TRUE) %>%
    visPhysics(solver = "forceAtlas2Based", 
               forceAtlas2Based = list(gravitationalConstant = -200),
               stabilization = FALSE)  %>%
    addFontAwesome()