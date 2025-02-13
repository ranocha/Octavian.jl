function __init__()
  init_acache()
  init_bcache()
  nt = init_num_tasks()
  if nt < num_cores() && ("OCTAVIAN_WARNING" ∈ keys(ENV))
    msg = string(
      "Your system has $(num_cores()) physical cores, but `Octavian.jl` only has ",
      "$(nt > 1 ? "$(nt) threads" : "$(nt) thread") available. ",
      "For the best performance, you should start Julia with at least $(num_cores()) threads.",
    )
    @warn msg
  end
  reseet_bcache_lock!()
end

function init_bcache()
  if bcache_count() ≢ Zero()
    BCACHEPTR[] = VectorizationBase.valloc(second_cache_size() * bcache_count(), Cvoid, ccall(:jl_getpagesize, Int, ()))
  end
  nothing
end

@static if Sys.WORD_SIZE ≤ 32
  function init_acache()
    ACACHEPTR[] = VectorizationBase.valloc(first_cache_size() * init_num_tasks(), Cvoid, ccall(:jl_getpagesize, Int, ()))
    nothing
  end
else
  init_acache() = nothing
end

function init_num_tasks()
  num_tasks = _read_environment_num_tasks()::Int
  OCTAVIAN_NUM_TASKS[] = num_tasks
end

function _read_environment_num_tasks()
  environment_variable = get(ENV, "OCTAVIAN_NUM_TASKS", "")::String
  nt = min(Threads.nthreads(), VectorizationBase.num_cores())::Int
  if isempty(environment_variable)
    return nt
  else
    return min(parse(Int, environment_variable)::Int, nt)
  end
end
