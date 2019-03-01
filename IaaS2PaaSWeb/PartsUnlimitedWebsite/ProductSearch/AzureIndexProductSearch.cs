using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Microsoft.Azure.Search;
using Microsoft.Azure.Search.Models;
using PartsUnlimited.Models;

namespace PartsUnlimited.ProductSearch
{
    public class AzureIndexProductSearch : IProductSearch
    {
        public async Task<IEnumerable<Product>> Search(string query)
        {
            List<Product> products = new List<Product>();

            try
            {
                DocumentSearchResult<Product> searchResults;

                var parameters = new SearchParameters()
                {
                    Select = new[] { "ProductId", "SkuNumber", "CategoryId", "Title", "Price", "SalePrice", "ProductArtUrl", "Description", "ProductDetails", "Inventory", "LeadTime" }
                };

                using (var searchClient = CreateSearchIndexClient())
                {
                    searchResults = await searchClient.Documents.SearchAsync<Product>(query, parameters);
                }

                foreach (var r in searchResults.Results)
                {
                    products.Add(r.Document);
                }
            }
            catch (Exception)
            {
                // Throw exception for easier troubleshooting
                throw;
            }

            return products;
        }

        private static SearchIndexClient CreateSearchIndexClient()
        {
            string searchServiceName = ConfigurationManager.AppSettings["SearchServiceName"];
            string queryApiKey = ConfigurationManager.AppSettings["SearchServiceQueryApiKey"];
            string indexName = ConfigurationManager.AppSettings["SearchServiceIndexName"];

            return new SearchIndexClient(searchServiceName, indexName, new SearchCredentials(queryApiKey));
        }

    }
}