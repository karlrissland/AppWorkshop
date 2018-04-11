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
            return (List<T>)Get(key);
        }

        public static void SetList<T>(string key, List<T> list)
        {
            Set(key, list);
        }

        public static object Get(string key)
        {
            return Deserialize<object>(Connection.GetDatabase().StringGet(key));
        }

        public static void Set(string key, object value)
        {
            Connection.GetDatabase().StringSet(key, Serialize(value));
        }

        static byte[] Serialize(object o)
        {
            if (o == null)
            {
                return null;
            }

            BinaryFormatter binaryFormatter = new BinaryFormatter();
            using (MemoryStream memoryStream = new MemoryStream())
            {
                binaryFormatter.Serialize(memoryStream, o);
                byte[] objectDataAsStream = memoryStream.ToArray();
                return objectDataAsStream;
            }
        }

        static T Deserialize<T>(byte[] stream)
        {
            if (stream == null)
            {
                return default(T);
            }

            BinaryFormatter binaryFormatter = new BinaryFormatter();
            using (MemoryStream memoryStream = new MemoryStream(stream))
            {
                T result = (T)binaryFormatter.Deserialize(memoryStream);
                return result;
            }
        }
    }
}
