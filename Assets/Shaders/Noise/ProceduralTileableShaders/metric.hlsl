float distanceMetric(float2 pos, uint metric)
{
    switch (metric)
    {
        case 0u:
            // squared euclidean
            return dot(pos, pos);
        case 1u:
            // manhattam   
            return dot(abs(pos), comp2(1.0));
        case 2u:
            // chebyshev
            return max(abs(pos.x), abs(pos.y));
        default:
            // triangular
            return  max(abs(pos.x) * 0.866025 + pos.y * 0.5, -pos.y);
    }
}

float4 distanceMetric(float4 px, float4 py, uint metric)
{
    switch (metric)
    {
        case 0u:
            // squared euclidean
            return px * px + py * py;
        case 1u:
            // manhattam   
            return abs(px) + abs(py);
        case 2u:
            // chebyshev
            return max(abs(px), abs(py));
        default:
            // triangular
            return max(abs(px) * 0.866025 + py * 0.5, -py);
    }
}
