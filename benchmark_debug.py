#!/usr/bin/env python3
"""
Benchmark Flask performance with and without debug mode
"""

import time
import requests
import threading
import statistics
from app import create_app

def run_server(debug_mode, port):
    """Run Flask server in specified mode"""
    app = create_app()
    
    def run():
        app.run(debug=debug_mode, host='127.0.0.1', port=port, use_reloader=False)
    
    thread = threading.Thread(target=run, daemon=True)
    thread.start()
    
    # Wait for server to start
    time.sleep(3)
    return thread

def benchmark_server(port, num_requests=50):
    """Benchmark server response times"""
    times = []
    
    for _ in range(num_requests):
        start = time.time()
        try:
            response = requests.get(f'http://127.0.0.1:{port}/', timeout=5)
            if response.status_code == 200:
                times.append(time.time() - start)
        except:
            pass
    
    return times

def main():
    print("🔍 Flask Debug Mode Performance Benchmark")
    print("=" * 50)
    
    # Test with debug=True
    print("\n🐞 Testing with DEBUG=True...")
    debug_thread = run_server(debug_mode=True, port=5001)
    
    debug_times = benchmark_server(5001, 20)
    if debug_times:
        debug_avg = statistics.mean(debug_times)
        debug_median = statistics.median(debug_times)
        print(f"   Average response time: {debug_avg*1000:.1f}ms")
        print(f"   Median response time:  {debug_median*1000:.1f}ms")
        print(f"   Requests completed:     {len(debug_times)}/20")
    else:
        print("   ❌ Failed to connect to debug server")
        return
    
    # Test with debug=False
    print("\n⚡ Testing with DEBUG=False...")
    no_debug_thread = run_server(debug_mode=False, port=5002)
    
    no_debug_times = benchmark_server(5002, 20)
    if no_debug_times:
        no_debug_avg = statistics.mean(no_debug_times)
        no_debug_median = statistics.median(no_debug_times)
        print(f"   Average response time: {no_debug_avg*1000:.1f}ms")
        print(f"   Median response time:  {no_debug_median*1000:.1f}ms")
        print(f"   Requests completed:     {len(no_debug_times)}/20")
    else:
        print("   ❌ Failed to connect to no-debug server")
        return
    
    # Calculate improvement
    if debug_times and no_debug_times:
        improvement = ((debug_avg - no_debug_avg) / debug_avg) * 100
        speedup = debug_avg / no_debug_avg
        
        print(f"\n📊 Performance Results:")
        print(f"   Debug mode:     {debug_avg*1000:.1f}ms avg")
        print(f"   No debug mode:  {no_debug_avg*1000:.1f}ms avg")
        print(f"   Improvement:    {improvement:.1f}% faster")
        print(f"   Speedup:        {speedup:.2f}x")
        
        print(f"\n💡 Recommendations:")
        if improvement > 20:
            print("   ✅ Significant performance improvement without debug")
            print("   🚀 Use debug=False for performance testing")
        elif improvement > 10:
            print("   ✅ Moderate performance improvement")
            print("   👍 Consider debug=False for testing")
        else:
            print("   ℹ️  Minimal performance difference")
            print("   🤔 Debug mode overhead is acceptable for development")

if __name__ == '__main__':
    main()
