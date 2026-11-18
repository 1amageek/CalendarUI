func currentTimeHandIsVisible(_ hasStarted: Bool, _ isBeforeEnd: Bool) -> Bool {
    if hasStarted {
        return isBeforeEnd
    } else {
        return false
    }
}
