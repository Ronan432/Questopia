package org.qp.android.ui.game

import android.net.Uri
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.CountDownLatch

data class InputDialogData(val title: String, val inputQueue: ArrayBlockingQueue<String>)
data class MessageDialogData(val message: String, val latch: CountDownLatch)
data class MenuDialogData(val items: List<String>, val resultQueue: ArrayBlockingQueue<Int>)
data class ErrorDialogData(val message: String)
data class SlotInfo(val index: Int, val isPresent: Boolean, val timeStr: String?, val fileUri: Uri?)
