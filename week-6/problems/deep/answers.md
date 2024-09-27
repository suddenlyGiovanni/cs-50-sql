# From the Deep

In this problem, you'll write freeform responses to the questions provided in the specification.

## Random Partitioning

Random partitioning is a good solution only if the problem is constrained to evenly distributing the information and/or
the database write load across multiple nodes (e.g., "round-robin").
However, as soon as efficient data inspection (e.g., by a specific time frame) is required, this strategy falls flat.

Let's illustrate the steps we would have to take to make some observations:

1. **Gather** all the data from each partition
2. **Combine** the results into a single dataset
3. **Sort** the data by some arbitrary criteria
4. **Analyze** the data based on specific requirements

The sum of all these operations is extremely costly.

## Partitioning by Hour

Partitioning by hour is a good strategy if the main concern is simplifying querying data within a given time frame.
However, due to the domain knowledge that data points are concentrated in the evening and early morning hours, this
results in uneven data distribution across partitions. If we use a naive time frame subdivision, the majority of data
points will fall into just two nodes: night-to-early-morning and late-evening-to-night.

### Pros:

- Ease of querying, as the data partition is based on known time frames

### Cons:

- Uneven data distribution due to the specific data generation patterns
- Uneven database load on both reads and writes, because client operations concentrate only on a subset of the available
  nodes
- To alleviate this issue, we could try to optimize time partitioning by defining arbitrary, uneven intervals, thus
  forcefully distributing the data in a more even way. However, this optimization would hinder our ability to easily
  query data across meaningful time intervals, thus invalidating the main advantage of this approach.

## Partitioning by Hash Value

Partitioning by hash value is an effective strategy if we want to optimize for even distribution of the dataset and ease
of querying for a single data point.

### Pros:

- Even data distribution across nodes based on some arbitrary hashing partition logic.
- Write operations become straightforward, as they involve computing the hashing function, e.g.:
  - `boat_a` (values 0-499)
  - `boat_b` (values 500-999)
  - `boat_c` (values 1000-1499)
- Ease of querying for a known primary key, as we can always apply the hashing function to the key and get a value that
  we can use to index the correct partition (e.g., query for a specific observation, which occurred at exactly
  `2023-11-01 00:00:01.020`, which computes to a hash value of 45, therefore pointing us to look into the `boat_a`
  partition).

### Cons:

- Querying for a set of values, where we either don't know their hash values or can't compute them, results in having to
  query across partitions. This makes such operations very slow and compute-intensive.
