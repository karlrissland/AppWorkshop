using Newtonsoft.Json;
using StackExchange.Redis;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;

namespace PartsUnlimited.Utils
{
    static class RedisHelper
    {
        private static JsonSerializerSettings serializerSettings;

        static RedisHelper()
        {
            serializerSettings = new JsonSerializerSettings
            {
                ReferenceLoopHandling = ReferenceLoopHandling.Ignore
            };
        }

        private static Lazy<ConnectionMultiplexer> lazyConnection = new Lazy<ConnectionMultiplexer>(() =>
        {
            string redisHost = ConfigurationManager.AppSettings["RedisCacheConnectionString"];

            return ConnectionMultiplexer.Connect(redisHost);
        });

        public static ConnectionMultiplexer Connection
        {
            get
            {
                return lazyConnection.Value;
            }
        }

        public static T Get<T>(string key)
        {
            var r = Connection.GetDatabase().StringGet(key);
            return Deserialize<T>(r);
        }

        public static List<T> GetList<T>(string key)
        {
            return Get<List<T>>(key);
        }

        public static void SetList<T>(string key, List<T> list)
        {
            Set(key, list);
        }

        public static void Set(string key, object value)
        {
            Connection.GetDatabase().StringSet(key, Serialize(value));
        }

        static string Serialize(object o)
        {
            if (o == null)
            {
                return null;
            }

            return JsonConvert.SerializeObject(o, serializerSettings);
        }

        static T Deserialize<T>(string value)
        {
            if (value == null)
            {
                return default(T);
            }

            return JsonConvert.DeserializeObject<T>(value, serializerSettings);
        }
    }
}
