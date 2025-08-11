import org.apache.spark.sql.SparkSession

import org.apache.spark.SparkContext
import org.apache.spark.SparkConf

object WordCount {
  def main(args: Array[String]): Unit = {
    // Create a SparkConf object and set the application name
    val conf = new SparkConf().setAppName("WordCountExample").setMaster("local[*]")

    // Create a SparkContext object
    val sc = new SparkContext(conf)

    // Define the input data as a sequence of strings (lines of text)
    val lines = sc.parallelize(Seq(
      "This is a sample text for word count",
      "Another line of text for counting words",
      "Word count example in Scala"
    ))

    // Perform the word count
    val counts = lines
      .flatMap(line => line.split("\\s+")) // Split each line into words using whitespace as delimiter
      .map(word => word.toLowerCase)      // Convert words to lowercase for case-insensitive counting
      .filter(word => word.nonEmpty)      // Filter out empty strings that might result from splitting
      .map(word => (word, 1))             // Create key-value pairs of (word, 1)
      .reduceByKey(_ + _)                 // Sum the counts for each word

    // Print the word counts
    counts.collect().foreach(println)

    // Stop the SparkContext
    sc.stop()
  }
}